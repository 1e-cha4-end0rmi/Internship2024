name: Build and Push Docker Image on New Tag
on:
push:
tags:
- 'v[0-9]+.[0-9]+.[0-9]+' # 1桁の数字のみのタグにマッチ
env:
REGISTRY: ghcr.io
permissions:
packages: write
contents: write
jobs:
BuildImage:
runs-on: ubuntu-latest
outputs:
latest-tag: ${{ steps.compare_tags.outputs.new_image_tag }}
steps:
# リポジトリのチェックアウト
- name: Check out the repository
uses: actions/checkout@v3
# GitHub Container Registry から最新のイメージタグを取得
- name: Get latest image tag from GHCR
id: get_image_tag
run: |
IMAGE_TAGS=$(curl -s -H "Authorization: Bearer ${{ secrets.GITHUB_TOKEN }}" \
https://ghcr.io/v2/${{ github.repository }}/tags/list | jq -r '.tags[]' | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' | sort -V | tail -n 1)
if [ -z "$IMAGE_TAGS" ]; then
IMAGE_TAGS="v0.0.0"
fi
echo "Latest image tag: $IMAGE_TAGS"
echo "latest_image_tag=$IMAGE_TAGS" >> $GITHUB_ENV
# 現在のGitタグと比較し、異なる場合のみビルドを実行
- name: Compare tags
id: compare_tags
run: |
CURRENT_TAG=${GITHUB_REF##*/}
if [ "$CURRENT_TAG" \<= "${{ env.latest_image_tag }}" ]; then
echo "The current tag ($CURRENT_TAG) is not greater than the latest image tag (${{ env.latest_image_tag }}). Skipping build."
exit 0
else
echo "New tag detected: $CURRENT_TAG"
echo "new_image_tag=$CURRENT_TAG" >> $GITHUB_ENV
echo "new_image_tag=$CURRENT_TAG" >> $GITHUB_OUTPUT
fi
# Docker Buildxのセットアップ
- name: Set up Docker Buildx
uses: docker/setup-buildx-action@v2
# GitHub Container Registryへのログイン
- name: Log in to GitHub Container Registry
uses: docker/login-action@v3
with:
registry: ${{ env.REGISTRY }}
username: ${{ github.actor }}
password: ${{ secrets.GITHUB_TOKEN }}
# Dockerイメージのビルドとプッシュ
- name: Build and push Docker image
if: success() # 前のステップが成功した場合のみ実行
uses: docker/build-push-action@v5
with:
context: .
push: true
platforms: linux/arm64 # ARM64アーキテクチャを指定
tags: |
ghcr.io/${{ github.repository }}:${{ env.new_image_tag }}
ghcr.io/${{ github.repository }}:latest
