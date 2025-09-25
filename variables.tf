variable "aws_region" {
    type = string
    default = "us-east-1"
  
}

variable "project_name" {
    type = string
    default = "flask-webapp"

}

variable "instance_type" {
    type = string
    default = "t2.micro"
  
}

variable "github_repo" {
    type = string
    default = "https://github.com/mmumshad/simple-webapp-flask.git"
}

variable "public_key_path" {
    type = string
    default = "C:/Users/phaiz/Documents/keys/keys.pub"
}
variable "private_key_path" {
    type = string
    default = "C:/Users/phaiz/Documents/key_private/jenkin.pem"
}
