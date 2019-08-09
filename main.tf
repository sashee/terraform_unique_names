provider "aws" {
}

resource "random_id" "id" {
  byte_length = 8
}

# the name is unique
resource "aws_s3_bucket" "bucket" {
	force_destroy = "true"
}

data "archive_file" "lambda_zip" {
	type = "zip"
	output_path = "/tmp/lambda.zip"

	source {
		filename = "main.js"
		content =<<EOF
module.exports.handler = async (event, context, callback) => {
	const response = {
		statusCode: 200,
		body: "Hello World!",
	};
	callback(null, response);
};
EOF
	}
}

# function_name is required
resource "aws_lambda_function" "lambda" {
	function_name = "${random_id.id.hex}-function"
# function_name = "function"

  filename = "${data.archive_file.lambda_zip.output_path}"
  source_code_hash = "${data.archive_file.lambda_zip.output_base64sha256}"

  handler = "main.handler"
  runtime = "nodejs10.x"
  role = "${aws_iam_role.lambda_exec.arn}"
}

resource "aws_iam_role" "lambda_exec" {
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}
