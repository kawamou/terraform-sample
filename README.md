# terraform-sampler
## terraformとは
```
AWS CloudFormationみたいに構成管理するためのツール
IaC(Infrastructure as Code)
```
## とりあえず触ってみる編
インストール
```
❯ brew install terraform
```
動作確認
```
❯ terraform
Usage: terraform [-version] [-help] <command> [args]
（略）
```
作業環境作る
```
❯ mkdir terraform
❯ cd terraform
```
IAM作る
```
- AWSコンソール > IAM > ユーザ追加
- 最後に表示されるアクセスキーとシークレットアクセスキーをコピー
```
awscliにユーザー追加
```
❯ aws configure --profile terraform # 名前はなんでもOK
AWS Access Key ID [None]: [ACCESS-KEY]
AWS Secret Access Key [None]: [SECRET-KEY]
Default region name [None]: ap-northeast-1
Default output format [None]: json
```
.aws/configにユーザーが追加されているの確認
```
~/.aws
❯ cat config
[profile terraform]
region = ap-northeast-1
output = json
```
.tfファイル内のresourceに記述したものがリソースとして管理される

```example.tf
provider "aws" {
  profile    = "IAMユーザー名"
  region     = "ap-northeast-1"
}

resource "aws_instance" "example" {
    ami = "ami-04b2d1589ab1d972c"
    instance_type = "t2.micro"
}
```

次にterraformワークスペースを初期化する。initコマンドで.tfファイルで利用してるpluginのダウンロード処理が走る。ダウンロードしたファイル群は直下の.terraformに入る
```
❯ terraform init
```
.tfファイルに記載された情報を元にリソースを作成する。リソースが作成されると`terraform.state`に作成されたリソースに関する情報が保存される。2度目以降の実行後には、1世代前のものが`terraform.tfstate.backup`に保存される
```
❯ terraform apply
```
上記コマンド実行後ダッシュボード確認すると確かにEC2が作成されている

下記、リソースの状態を確認するコマンド
```
❯ terraform show
```
構文チェックコマンド
```
❯ terraform validate
```
スタイル整形
```
❯ terraform fmt
```
リソースを削除するコマンド
```
❯ terraform destroy
```
## .tfファイル上書きしてみる編
terraformはのサイクルは`plan→apply→show`の順番。planで.tfファイルが更新されてるか確認し、applyで適用し、showで現在のリソースの状態を確認する。早速.tfファイルを編集してみる。80番ポートを開けたガバガバセキュリティグループを追加した

```example.tf
provider "aws" {
  profile    = "terraform"
  region     = "ap-northeast-1"
}

# resource "インスタンスの作成" "名前"
resource "aws_instance" "example" {
    ami = "ami-04b2d1589ab1d972c"
    instance_type = "t2.micro"
    vpc_security_group_ids = ["${aws_security_group.sg.id}"]

    tags = {
        Name = "terraform-example"
    }
}

resource "aws_security_group" "sg" {
    name = "terraform-example-sg"
    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

planで確認してみると確かに編集されたことが確認できる
```
❯ terraform plan
Refreshing Terraform state in-memory prior to plan...
The refreshed state will be used to calculate this plan, but will not be
persisted to local or remote state storage.


------------------------------------------------------------------------

（中略）

Plan: 2 to add, 0 to change, 0 to destroy.

------------------------------------------------------------------------

Note: You didn't specify an "-out" parameter to save this plan, so Terraform
can't guarantee that exactly these actions will be performed if
"terraform apply" is subsequently run.
```
変更を適用する
```
❯ terraform apply
```
ダッシュボード確認するとセキュリティグループ紐付けられたEC2が確認できる。お遊びリソースなので削除
```
❯ terraform destroy
```
## 本番でも使えそうな構成作ってみる編
### .tfファイルはリソースごとに分けた
```
❯ ls
README.md            provider.tf          route_table.tf
igw.tf               route.tf             subnet.tf
nat.tf               route_association.tf vpc.tf
```
![image](https://user-images.githubusercontent.com/18514782/75225731-8ac1a180-57ee-11ea-959d-717edaa500ad.png)
### 使い方
```
# 使う前に"terraform"って名前のIAMユーザー作っといてください
❯ git clone [this repository]
❯ terraform init
❯ terraform apply
```
## 参考
- https://qiita.com/pokotyan/items/da3d4a0a8cd8dfacbd32
- https://blog.mzumi.com/post/2016/09/01/terraform-private-subnet/
