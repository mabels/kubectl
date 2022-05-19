package main

import (
	"fmt"

	"github.com/pulumi/pulumi-aws/sdk/v5/go/aws"
	"github.com/pulumi/pulumi-aws/sdk/v5/go/aws/ec2"
	"github.com/pulumi/pulumi-aws/sdk/v5/go/aws/iam"
	"github.com/pulumi/pulumi-aws/sdk/v5/go/aws/secretsmanager"

	"github.com/pulumi/pulumi-github/sdk/v4/go/github"

	"github.com/pulumi/pulumi/sdk/v3/go/pulumi"
)

func main() {

	pulumi.Run(func(ctx *pulumi.Context) error {
		callerId, err := aws.GetCallerIdentity(ctx, nil, nil)
		project := "kubectl"
		githubUser := "mabels"


		// OCID Github Role + EC2 Create
		oicp, err := iam.GetOpenIdConnectProvider(ctx, "github-provider",
			pulumi.ID(fmt.Sprintf("arn:aws:iam::%s:oidc-provider/token.actions.githubusercontent.com",
				callerId.AccountId)),
			&iam.OpenIdConnectProviderState{})
		if err != nil {
			oicp, _ = iam.NewOpenIdConnectProvider(ctx, "github-provider", &iam.OpenIdConnectProviderArgs{
				Url:             pulumi.String("https://token.actions.githubusercontent.com"),
				ClientIdLists:   pulumi.StringArray{pulumi.String("sts.amazonaws.com")},
				ThumbprintLists: pulumi.StringArray{pulumi.String("6938fd4d98bab03faadb97b34396831e3780aea1")},
			})
		}
		ghRunnerRole, _ := iam.NewRole(ctx, "github-runner", &iam.RoleArgs{
			Name: pulumi.Sprintf("%s-github-runner", project),
			AssumeRolePolicy: pulumi.Sprintf(`{
				"Version": "2008-10-17",
				"Statement": [
					{
						"Effect": "Allow",
						"Principal": {
							"Federated": "%s"
						},
						"Action": "sts:AssumeRoleWithWebIdentity",
						"Condition": {
							"StringLike": {
								"token.actions.githubusercontent.com:sub": "repo:%s/%s:*"
							}
						}
					}
				]
			}`, oicp.Arn, githubUser, project),
		})
		iam.NewRolePolicyAttachment(ctx, "ecr-power-user", &iam.RolePolicyAttachmentArgs{
			Role:      ghRunnerRole,
			PolicyArn: pulumi.String("arn:aws:iam::aws:policy/AmazonElasticContainerRegistryPublicPowerUser"),
		})
		iam.NewRolePolicy(ctx, "iam-get-pass-role", &iam.RolePolicyArgs{
			Role: ghRunnerRole,
			Policy: pulumi.Sprintf(`{
			"Version": "2012-10-17",
			"Statement": [
				{
					"Effect": "Allow",
					"Action": [
						"iam:GetRole",
						"iam:PassRole"
					],
					"Resource": "%s" 
				}
			]
		}`, ec2GHRunnerRole.Arn),
		})

		// ctx.Export("roleArn", allowS3ManagementRole.Arn)
		// ctx.Export("accessKeyId", unprivilegedUserCreds.ID().ToStringOutput())
		// ctx.Export("secretAccessKey", unprivilegedUserCreds.Secret)
		return nil
	})
}
