# terraform-sampler
terraformとは
```
AWS CloudFormationみたいに構成管理するためのツール
IaC(Infrastructure as Code)
## ハローワールドしてみる
```
インストール
```
❯ brew install terraform
```
動作確認
```
❯ terraform
Usage: terraform [-version] [-help] <command> [args]

The available commands for execution are listed below.
The most common, useful commands are shown first, followed by
less common or more advanced commands. If you're just getting
started with Terraform, stick with the common commands. For the
other commands, please read the help and docs before usage.

Common commands:
    apply              Builds or changes infrastructure
    console            Interactive console for Terraform interpolations
    destroy            Destroy Terraform-managed infrastructure
    env                Workspace management
    fmt                Rewrites config files to canonical format
    get                Download and install modules for the configuration
    graph              Create a visual graph of Terraform resources
    import             Import existing infrastructure into Terraform
    init               Initialize a Terraform working directory
    login              Obtain and save credentials for a remote host
    logout             Remove locally-stored credentials for a remote host
    output             Read an output from a state file
    plan               Generate and show an execution plan
    providers          Prints a tree of the providers used in the configuration
    refresh            Update local state file against real resources
    show               Inspect Terraform state or plan
    taint              Manually mark a resource for recreation
    untaint            Manually unmark a resource as tainted
    validate           Validates the Terraform files
    version            Prints the Terraform version
    workspace          Workspace management

All other commands:
    0.12upgrade        Rewrites pre-0.12 module source code for v0.12
    debug              Debug output management (experimental)
    force-unlock       Manually unlock the terraform state
    push               Obsolete command for Terraform Enterprise legacy (v1)
    state              Advanced state management
```
作業環境作る
```
❯ mkdir terraform
❯ cd terraform
```
IAM作る
```
- AWSコンソール > IAM > ユーザ追加
- 最後に表示されるアクセスキーIDとシークレットアクセスキーをコピー
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
terraformのファイル作る
.tfファイル内のresourceに記述したものがリソースとして管理される
profileに先程作成したユーザ名を記入
```example.tf
provider "aws" {
  profile    = "USER"
  region     = "ap-northeast-1"
}

resource "aws_instance" "example" {
    ami = "ami-04b2d1589ab1d972c"
    instance_type = "t2.micro"
}
```
次にterraformワークスペースを初期化する
initコマンドで.tfファイルで利用してるpluginのダウンロード処理が走る
plugin：aws providerとか
ダウンロードしたファイル群は直下の.terraformに入る
```
❯ terraform init
```
.tfファイルに記載された情報を元にリソースを作成する
リソースが作成されるとterraform.stateに作成されたリソースに関する情報が保存される
2度目以降の実行後には、1世代前のものがterraform.tfstate.backupに保存される
```
❯ terraform apply
```
上記コマンド実行後ダッシュボード確認すると確かにEC2が作成されている
下記、リソースの状態を確認するコマンド
```
❯ terraform show
```
リソースを削除するコマンド
```
❯ terraform destroy
```
## .tfファイルを上書く
terraformはのサイクルはplan→apply→showの順番
planで.tfファイルが更新されてるか確認し、applyで適用し、showで現在のリソースの状態を確認する
早速.tfファイルを編集してみる
80番ポートを開けたガバガバセキュリティグループを追加した
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
ダッシュボード確認するとセキュリティグループ紐付けられたEC2が確認できる
お遊びリソースなので削除
```
❯ terraform destroy
```