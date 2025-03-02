# Use Intel Optimized ML libraries on  AWS Sagemaker


## 1.  Deep Learning Image with Intel Optimized ML libraries
### Getting started

We describe here the setup to build and test the images on the platforms Amazon SageMaker, EC2, ECS and EKS.

We take an example of building a ***Tensorflow CPU python3 training*** container.

* Ensure you have access to an AWS account i.e. [setup](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html) 
your environment such that awscli can access your account via either an IAM user or an IAM role. We recommend an IAM role for use with AWS. 
For the purposes of testing in your personal account, the following managed permissions should suffice: <br>
-- [AmazonEC2ContainerRegistryFullAccess](https://console.aws.amazon.com/iam/home#policies/arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess) <br>
-- [AmazonEC2FullAccess](https://console.aws.amazon.com/iam/home#policies/arn:aws:iam::aws:policy/AmazonEC2FullAccess) <br>
-- [AmazonEKSClusterPolicy](https://console.aws.amazon.com/iam/home#policies/arn:aws:iam::aws:policy/AmazonEKSClusterPolicy) <br>
-- [AmazonEKSServicePolicy](https://console.aws.amazon.com/iam/home#policies/arn:aws:iam::aws:policy/AmazonEKSServicePolicy) <br>
-- [AmazonEKSServiceRolePolicy](https://console.aws.amazon.com/iam/home#policies/arn:aws:iam::aws:policy/AmazonEKSServiceRolePolicy) <br>
-- [AWSServiceRoleForAmazonEKSNodegroup](https://console.aws.amazon.com/iam/home#policies/arn:aws:iam::aws:policy/AWSServiceRoleForAmazonEKSNodegroup) <br>
-- [AmazonSageMakerFullAccess](https://console.aws.amazon.com/iam/home#policies/arn:aws:iam::aws:policy/AmazonSageMakerFullAccess) <br>
-- [AmazonS3FullAccess](https://console.aws.amazon.com/iam/home#policies/arn:aws:iam::aws:policy/AmazonS3FullAccess) <br>
* [Create](https://docs.aws.amazon.com/cli/latest/reference/ecr/create-repository.html) an ECR repository with the name “intel-tensorflow” in the us-west-2 region
* Ensure you have [docker](https://docs.docker.com/get-docker/) client set-up on your system

1. Clone  [AWS Deep Learning Containers](https://github.com/aws/deep-learning-containers.git) repo and apply the [patch](./patch/Use-intel-tensorflow-to-build-sagemaker-image.patch)
    ```
    git clone https://github.com/aws/deep-learning-containers.git -b 23987d4c3bb34868ef097e7be058
    cd deep-learning-containers
    cp $OAP-TOOLS/integrations/ml/sagemaker/patch/Use-intel-tensorflow-to-build-sagemaker-image.patch ./
    git am --signoff < Use-intel-tensorflow-to-build-sagemaker-image.patch
    ```
2. Set the following environment variables: 
    ```shell script
    export ACCOUNT_ID=<YOUR_ACCOUNT_ID>
    export REGION=us-west-2
    # Please make sure you have created the repository
    export REPOSITORY_NAME=intel-tensorflow
    ``` 
3. Login to ECR
    ```shell script
    aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.us-west-2.amazonaws.com
    ``` 
4. Assuming your working directory is the cloned repo, create a virtual environment to use the repo and install requirements
    ```shell script
    python3 -m venv dlc
    source dlc/bin/activate
    pip install -r src/requirements.txt
    ``` 
5. Perform the initial setup
    ```shell script
    bash src/setup.sh tensorflow
    ```
### Building your image

The paths to the dockerfiles follow a specific pattern e.g., tensorflow/training/docker/\<version>/\<python_version>/Dockerfile.<processor>
These paths are specified by the buildspec.yml residing in tensorflow/buildspec.yml i.e. \<framework>/buildspec.yml. 


 To build an image with Intel Tensorflow.
```shell script
python src/main.py --buildspec tensorflow/buildspec.yml \
                    --framework tensorflow \
                    --image_types training \
                    --device_types cpu \
                    --py_versions py3
```
The above step should take a while to complete the first time you run it since it will have to download all base layers and create intermediate layers for the first time. Subsequent runs should be much faster.
When the build is completed, the URL of the image will be output in the log.

### Test your image
#### Test the images on your local machine.

Create an IAM role with name “SageMakerRole” in the above account and add the below AWS Manged policies
>AmazonSageMakerFullAccess

```
cd $oap-tools/integrations/ml/sagemaker/benchmark/local/mnist
# We recommend that you create a new environment with CONDA to run benchmark.
pip3 install sagemaker boto3
# Replace the value of 'ecr_image' with your image URL in the file benchmark_mnist_local.py.
python3 benchmark_mnist_local.py
```
When you see  "reporting training success" in the output screem, it means that the training is successfully completed and the image is built correctly.


#### Test the images with Sagemaker notebook instance.

1. Create a notebook instance.
2. Upload the [notebook and data](benchmark/notebook-instance/mnist/tensorflow_mnist_train.ipynb) to the Jupyter notebook. Replace the value of 'ecr_image' with your image URL in the notebook.
3. Run all.

