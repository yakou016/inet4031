# Release conventions

## Branches and commits

Use descriptive branches and pull requests for changes.
Use feat, fix, docs, test, or chore prefixes where appropriate.
Intentional negative-test PRs must say do not merge and be closed unmerged.
Do not disable local hooks to create negative-test commits.

## Version and image identity

Use annotated Git tags in vMAJOR.MINOR.PATCH format.
The first lab release is v0.1.0.
Use the same version in the Docker image tag and OpenTofu declaration.
Never move an existing release tag or overwrite its image.
Keep previous release images available for rollback.

The image revision label identifies its application-source commit.
The annotated Git tag identifies the merged release-configuration commit.
These commits can differ when preparation changes only deployment files,
checks, or documentation. Record both identities.

## Release checks

Build a candidate and record its source and image identity.
Apply SECURITY-POLICY.md and retain both full and filtered scan reports.
Run the expanded smoke test against that exact image with isolated test data.
Import the tested image before merging the deployment-image change.
Review all seven PR checks, even while new checks remain non-required.
Preserve the existing three required checks and protect-master enforcement.

After merge, require the master deploy gate to pass.
Deploy through week-7/deploy.sh, verify rollout, image identity, health JSON,
and live checks. Only then create and push the annotated release tag.
Do not substitute a manual kubectl image change.

## Rollback

Use a PR to restore the previous release image in OpenTofu.
Keep both release images imported before starting the exercise.
Measure from the rollback PR's actual merge time until the older image is
ready and serves a successful /health response.
The target is under five minutes. Record the actual duration, including
a missed target if that occurs.

Do not restore the database for an image-only rollback.
Never delete live volumes or use broad Docker cleanup commands.
