[![Build Status](https://status.continuousphp.com/git-hub/continuousdemo/wordpress-eb-demo?token=685bd047-749e-40c5-9678-7dc1048c2308)](https://continuousphp.com/git-hub/continuousdemo/wordpress-eb-demo)

# WordPress Docker Development with Deployment on AWS Elastic Beanstalk

- [Introduction](#introduction)
- [Requirements](#requirements)
- [Set-up your Development environment](#set-up-your-development-environment)
  - [Prepare your WordPress Repository](#prepare-your-wordpress-repository)
  - [Dependencies management with composer](#dependencies-management-with-composer)
  - [Phing environment variables](#phing-environment-variables)
  - [Configuring Wordpress](#configuring-wordpress)
  - [Starting docker-compose](#starting-docker-compose)
  - [Initializing the Database](#initializing-the-database)
  - [WordPress Base Install](#wordpress-base-install)
  - [Configuring your development environment](#configuring-your-development-environment)
    - [Plugin Installation](#plugin-installation)
    - [Running the behat tests](#running-behat-tests)
    - [Themes Installation](#themes-installation)
    - [Developing a dumy plugin](#developing-a-dumy-plugin)
- [Set-up AWS Elastic BeanStalk Staging environment](#set-up-aws-elastic-beanstalk-staging-environment)
  - [Set-up the AWS environment accounts](#set-up-the-aws-environment-accounts)
  - [Set-up the WordPress backup S3 bucket](#set-up-the-wordpress-backup-s3-bucket)
  - [Set-up the WordPress backup S3 bucket IAM policy](#set-up-the-wordpress-backup-s3-bucket-iam-policy)
  - [Configuring the UpdraftPlus WordPress plugin](#configuring-the-updraftplus-wordpress-plugin)
  - [Creating the EC2 Key Pair](#creating-the-ec2-key-pair)
  - [Creating the MySQL DB Instance](#creating-the-mysql-db-instance)
  - [Set-up your Elastic BeanStalk Application](#set-up-your-elastic-beanstalk-application)
  - [Create your Staging Application Environment](#create-your-staging-application-environment)
  - [Configuring the DocumentRoot](#configuring-the-documentroot)
  - [Configuring the WordPress Site URL](#configuring-the-wordpress-site-url)
  - [Adding the EC2 Security Group to your RDS Database](#Adding-the-ec2-security-group-to-your-rds-database)
  - [Set up the IAM permissions](#set-up-the-iam-permissions)
- [Set-up continuousphp](#set-up-continuousphp)
  - [Application Project Set-up in continuousphp](#application-project-set-up-in-continuousphp)
  - [Deployment pipeline Configuration](#deployment-pipeline-configuration)
  - [Deploying Wordpress](#deploying-wordpress)
- [Notes](#notes)

## Introduction

Have you ever been scared on clicking on that WordPress or plugins update button ?

Have you ever wanted to have a staging environement for the validation of your latest development by your customers and to update the production with one push upon validation ?

Have you ever wanted to have automated test to ensure proper site function before deployments ?

The goal of this project is to have a WordPress environment that let you develop, test, package and deploy an immutable WordPress on different environments like staging and production.

It is based on docker-compose for the local development, [continuousphp](https://continuousphp.com) for building, testing and deploying on AWS Elastic BeanStalk Infrastructure environments.

So let's start! 

## Requirements

* docker
* docker-compose
* composer
* AWS account

## Set-up your Development environment

### Prepare your WordPress Repository

Fork and clone the [WordPress Elastic BeanStalk Demo](https://github.com/continuousdemo/wordpress-eb-demo).

Because we are going to configure continuousphp in staging environment, we need to create a develop branch, for which we will create a deployment pipeline.

Create the **develop** branch:

```bash
git checkout -B develop
git push origin develop
```

This WordPress Repository include the following files:

* [composer.json](https://github.com/continuousdemo/wordpress-eb-demo/blob/master/composer.json) with our WordPress dependencies
* [build.xml](https://github.com/continuousdemo/wordpress-eb-demo/blob/master/build.xml) with the phing targets
* [build.properties](https://github.com/continuousdemo/wordpress-eb-demo/blob/master/build.properties) with our Phing property file 
* [scripts](https://github.com/continuousdemo/wordpress-eb-demo/blob/master/scripts/) with our provisioning scripts  
* [wp-content](https://github.com/continuousdemo/wordpress-eb-demo/blob/master/wp-content/) with our custom WordPress content 
* [wp-root](https://github.com/continuousdemo/wordpress-eb-demo/blob/master/wp-root/) with our root configuration WordPress content 
* [.ebextensions/project.config](https://github.com/continuousdemo/wordpress-eb-demo/blob/master/.ebextensions/project.config) with the Elastic BeanStalk provisioning script. 
* [Dockerfile](https://github.com/continuousdemo/wordpress-eb-demo/blob/master/Dockerfile) with our Docker file 
* [docker-compose.yml](https://github.com/continuousdemo/wordpress-eb-demo/blob/master/docker-compose.yml) with docker-compose configuration file 
* [nginx](https://github.com/continuousdemo/wordpress-eb-demo/blob/master/nginx/) with nginx configuration files 
* [php](https://github.com/continuousdemo/wordpress-eb-demo/blob/master/php/) with php configuration files 
* [behat.yml](https://github.com/continuousdemo/wordpress-eb-demo/blob/master/tests/behat.yml) with the Behat configuration

These are key files to set-up your WordPress installation, development and deployment environement. Feel free to take a look at them to get a better understanding.

### Dependencies management with composer

Install Wordpress and plugins using composer like:

```
composer.phar install
```

### Phing environment variables

To set your local development environment copy the **build.local.properties.sample** to **build.local.properties**.

```
cp build.local.properties.sample build.local.properties
``` 

### Create the develop symlinks

Create the symlinks to enable plugins and themes in development mode:

```
./vendor/bin/phing wp-symlink-plugins
./vendor/bin/phing wp-symlink-themes
```

Most of the WP plugins can be found on [wordpress packagist](https://wpackagist.org/), add them to your composer.json like:

```
"require": {
"php": ">=7.0",
"johnpbloch/wordpress": ">=4.7.2",
"composer/installers": "~1.0",
"wpackagist-plugin/contact-form-7": "4.6.1",
"wpackagist-plugin/business-profile": "1.1.1",
"robmorgan/phinx": "~0.6.0",
"wp-cli/wp-cli": "^1.0",
"phing/phing": "~2.14"
},
```

### Configuring Wordpress

```
cp wp/wp-config-sample.php wp/wp-config.php 
```
Edit the wp/wp-config.php file and set WP configuration variables using $_SERVER environment variables as below, we do this to be able to provision the WP configuration for the differents environments like develop, staging and production.

```
/** The name of the database for WordPress */
define('DB_NAME',     $_SERVER["MYSQL_ADDON_DB"]);

/** MySQL database username */
define('DB_USER',     $_SERVER["MYSQL_ADDON_USER"]);

/** MySQL database password */
define('DB_PASSWORD', $_SERVER["MYSQL_ADDON_PASSWORD"]);

/** MySQL hostname */
define('DB_HOST',     $_SERVER["MYSQL_ADDON_HOST"]);

/** Database Charset to use in creating database tables. */
define('DB_CHARSET', 'utf8');

/** The Database Collate type. Don't change this if in doubt. */
define('DB_COLLATE', '');
```

and add:

```
define('AUTH_KEY',         $_SERVER["AUTH_KEY"]);
define('SECURE_AUTH_KEY',  $_SERVER["SECURE_AUTH_KEY"]);
define('LOGGED_IN_KEY',    $_SERVER["LOGGED_IN_KEY"]);
define('NONCE_KEY',        $_SERVER["NONCE_KEY"]);
define('AUTH_SALT',        $_SERVER["AUTH_SALT"]);
define('SECURE_AUTH_SALT', $_SERVER["SECURE_AUTH_SALT"]);
define('LOGGED_IN_SALT',   $_SERVER["LOGGED_IN_SALT"]);
define('NONCE_SALT',       $_SERVER["NONCE_SALT"]);
```

Once finished, copy the wp/wp-config.php in the wp-root/ folder, we will need it for the deployment provisioning. 

```
cp wp/wp-config.php wp-root/
```

Let's export the environment variables for our development environment:

```
export MYSQL_ADDON_HOST=192.168.99.100
export MYSQL_ADDON_DB=wordpress
export MYSQL_ADDON_PASSWORD=password
export MYSQL_ADDON_USER=root
export S3_BACKUP_URL=
export S3_MEDIA_URL=
export environment=develop
```

If you plan to use the WordPress Security Keys (which we recommend), [generate the keys](https://api.wordpress.org/secret-key/1.1/salt/) and export them:

```
export AUTH_KEY=""
export SECURE_AUTH_KEY=""
export LOGGED_IN_KEY=""
export NONCE_KEY=""
export AUTH_SALT=""
export SECURE_AUTH_SALT=""
export LOGGED_IN_SALT=""
export NONCE_SALT=""
```

Keep those keys in a safe place.

### Starting docker-compose

```
docker-compose up
``` 

Note: if you don't daemonize the docker-compose, you will need to open a new terminal, don't forget to export again your environment variables.

#### Initializing the Database

Now let's initialize our WP database.

```
./vendor/bin/phing reset-db
```

#### WordPress Base Install

Open in your browser http://192.168.99.100/wp-admin/install.php to install your WordPress.

Complete the information: 

* Site Title: Your site title
* Username: **admin**
* Search Engine Visibility: Check discourage search engines from indexing this site
* Click **Install WordPress**

Your WordPress is now ready to be customized.

Note: you may recieve a 500 Error because a phpmailerException, just refresh the page.

### Configuring your development environment

```
./vendor/bin/phing setup-dev
```

Note: don't worry about the wp-get-s3-backup and wp-get-s3-media target that fail, we will use them later on.

#### Plugin Installation

We are going to add a few plugins. 

* Updraftplus to backup our wordpress assets on S3. 
* The w3-total-cache Search Engine and Performance Optimization plugin

For this we add the "wpackagist-plugin/updraftplus" and "wpackagist-plugin/w3-total-cache" dependencies in our composer.json file like:

```
"require": {
"php": ">=7.0",
"johnpbloch/wordpress": ">=4.7.2",
"composer/installers": "~1.0",
"wpackagist-plugin/contact-form-7": "4.6.1",
"wpackagist-plugin/business-profile": "1.1.1",
"wpackagist-plugin/updraftplus": "1.12.32",
"wpackagist-plugin/w3-total-cache": "0.9.5.1",
"robmorgan/phinx": "~0.6.0",
"wp-cli/wp-cli": "^1.0",
"phing/phing": "~2.14"
},
```

Edit the **build.properties** and add our new plugins into the wp.plugins variables, this varibales is used by the Phing target wp-plugins-activate.

```
wp.plugins=business-profile,contact-form-7,updraftplus,w3-total-cache
```

Do the same to your **build.local.properties**.

Run a composer update to install the plugin.

```
composer.phar update
```

Then activate the plugins:

```
./vendor/bin/phing wp-plugins-activate
```

Open in your browser http://192.168.99.100/wp-admin/plugins.php the updraftplus plugin is installed and activated. Note that the password for the **admin** user is **password**, we have updated it so we can run automated test.

Notice all the plugin are installed and activated, but wait a minute, we W3 Total Cache that require an update, let's edit our composer.json and bump the version.

Get the latest version at [WordPress Packagist](https://wpackagist.org/search?q=w3-total-cache&type=any&search=)

``` 
"wpackagist-plugin/w3-total-cache": "0.9.5.2",
```

Run composer update and refresh the plugin page, our plugin is up to date!

```
composer.phar update
```

If you need to install a Plugin which isn't available on WordPress Packagist or that you have to build a custom plugin, add it into the project root in wp-content folder, it is symlinked into the WordPress install, so you can develop or make it available to WordPress.

#### Running the behat tests

To run the behat test locally first, copy the **behat.local.yml.sample** to **behat.local.yml**

```
cp tests/behat.local.yml.sample tests/behat.local.yml
```

Then run behat with:

```
./vendor/bin/behat -c tests/behat.local.yml
```

#### Themes Installation

Now let's install a theme, we do the same, adding it to our **composer.json** and run ```composer update```.

```
"wpackagist-theme/vanilla": "1.3.5"
```

Update the theme in the **build.properties** and **build.local.properties**

```
wp.theme=vanilla
```

And let's activate it:

```
./vendor/bin/phing wp-theme-activate 
```

Let's change our behat test by editing the **tests/features/homepage.feature** file with:

```
@home
Feature: As a visitor I should be able to load the home page

Scenario: Home page loads
Given I am on the homepage
Then I should see **"Just another WordPress site"**
```

and run behat again:

```
./vendor/bin/behat -c tests/behat.local.yml
```

We have now "Just another WordPress site"!

Now, let's develop a dummy-plugin.

#### Developing a dumy plugin

Let's develop a dumy plugin to show how it works, for this we create a dumy-plugin plugin into the root wp-content/plugins.

```
mkdir ./wp-content/plugins/dumy-plugin
cd ./wp-content/plugins/dumy-plugin
```

And add a **dumy-plugin.php** file with the following:

```
<?php
/*
Plugin Name: dumy-plugin 
Plugin URI:
Description: A Dumy plugin 
Author: John Doe
Version: 1.0
Author URI: https://www.johndoe-dumy-plugin.com
*/
?>
```

Open your browser to http://192.168.99.100/wp-admin/plugins.php and your plugin is displayed.

Add it to your **build.properties** and **build.local.properties**:

```
wp.plugins=business-profile,contact-form-7,updraftplus,w3-total-cache,wordpress-https,dumy-plugin
```

And let's activate it:

```
./vendor/bin/phing wp-plugins-activate
```

Same apply to the theme development. **Be sure to only commit your themes and plugins of the root wp-content folder, not the ones installed by composer**. 

So we have our base WordPress development ready, now we are going to create our staging environment on AWS Elastic BeanStalk.

## Set-up AWS Elastic BeanStalk Staging environment 

### Set-up the AWS environment accounts

AWS recommends the separation of responsibilities, and therefore you should create a separate AWS account for every environment you might require.

This tutorial explains Wordpress deployment in a **staging** environment. 

So let's start and create an AWS account for your staging environment.

**Set up a new account:**

1. Open [https://aws.amazon.com/](https://aws.amazon.com/), and then choose *Create an AWS Account*.
2. Follow the online instructions.

### Set-up the WordPress backup S3 bucket

Let's first create an S3 bucket for your WP backup.

**Create the backup bucket**

1. Sign-in to the AWS Management Console and open the Amazon S3 console at https://console.aws.amazon.com/s3.
2. Click *Create Bucket*.
3. In the *Create a Bucket* dialog box, fill in the *Bucket Name*. In this example we will use **"my-wordpress-site-backup"**.
4. In the *Region* box, select a region from the drop-down list.
5. Click Create.

When Amazon S3 has successfully created your bucket, the console displays your empty bucket **"my-wordpress-site-backup"** in the Bucket panel.

Let's configure the Bucket Polocy.

**Configuring the bucket policy**

1. Open the **my-wordpress-site-backup** bucket properties.
2. Goto **Permissions**
3. Select the **Bucket Policy** and add:

```
{
"Version": "2012-10-17",
"Statement": [
{
    "Sid": "PublicReadGetObject",
    "Effect": "Allow",
    "Principal": {
	"AWS": "*"
    },
    "Action": "s3:GetObject",
    "Resource": "arn:aws:s3:::my-wordpress-site-backup/*"
}
]
}
```

Note: To get your account ID goto on the AWS My Account.

### Set-up the WordPress backup S3 bucket IAM policy

Let's create an IAM policy to grant UpdraftPlus plugin the permission to upload the backups to your backup S3 bucket. 

**Create the policy**

1. Sign-in to the IAM console at https://console.aws.amazon.com/iam/ with your user that has administrator permissions.
2. In the navigation pane, choose *Policies*.
3. In the content pane, choose *Create Policy*.
4. Next to *Create Your Own Policy*, choose *Select*.
5. As *Policy Name*, type **my-wordpress-site-backup**.
6. As *Policy Document*, paste the following policy.

```
{
"Version": "2012-10-17",
"Statement": [
{
    "Effect": "Allow",
    "Action": [
	"s3:ListBucket",
	"s3:GetBucketLocation",
	"s3:ListBucketMultipartUploads"
    ],
    "Resource": "arn:aws:s3:::my-wordpress-site-backup",
    "Condition": {}
},
{
    "Effect": "Allow",
    "Action": [
	"s3:AbortMultipartUpload",
	"s3:DeleteObject",
	"s3:DeleteObjectVersion",
	"s3:GetObject",
	"s3:GetObjectAcl",
	"s3:GetObjectVersion",
	"s3:GetObjectVersionAcl",
	"s3:PutObject",
	"s3:PutObjectAcl",
	"s3:PutObjectAclVersion"
    ],
    "Resource": "arn:aws:s3:::my-wordpress-site-backup/*",
    "Condition": {}
},
{
    "Effect": "Allow",
    "Action": "s3:ListAllMyBuckets",
    "Resource": "*",
    "Condition": {}
}
]
}
```
7\. Choose *Validate Policy* and ensure that no errors display in a red box at the top of the screen. Correct any that are reported.

8\. Choose *Create Policy*.

Now let's create an IAM user with an Access Key and attach the policy we've just created.

**Create a new User and attach the User policy**

1. Sign-in to the Identity and Access Management (IAM) console at https://console.aws.amazon.com/iam/.
2. In the navigation pane, choose *Users* and then choose *Create New Users*.
3. Enter the following user: **my-wordpress-site-backup**
4. Select **Programmatic access** then click Next
5. Select **Attach existing policies directly**
6. Search for the policy we just made: **my-wordpress-site-backup**
7. Click Next the Create User 
8. **Save the generated access key in a safe place**.
9. Choose *Close*.

### Configuring the UpdraftPlus WordPress plugin

We are now going to configure the UpdraftPlus WordPress plugin. We use this plugin to keep a backup of our database and media files, so we can restore any of our environment from any backup.

Open your browser to http://192.168.99.100/wp-admin/plugins.php

1. Open the settings page of the UpdraftPlus plugin
2. Goto the Settings Tab and configure the Backup settings:
* File Backup schedule: Daily and retain this many scheduled backups: 15 Days
* Database backup schedule: Daily and retain this many scheduled backups: 15 Days
* Remote storage: Amazon S3
* S3 access key: \<YOUR my-wordpress-site-backup ACCESS_KEY\> 
* S3 secret key: \<YOUR my-wordpress-site-backup SECRET_KEY\>
* S3 location: my-wordpress-site-backup/
3. Click on **Test S3 Settings**
4. Click on **Save Changes**
5. Goto the Current Status Tab
6. Click on **Backup Now**, ensure all checks are checked.

Note: If you have an error with updraft folder is not writtable, create the folder and give it permission: ```mkdir wp/wp-content/updraft ; chmod 777 wp/wp-content/updraft```

UpdraftPlus Backup ensure we keep your WordPress state up to date on all environments and be able to restore a version if needed.

Let's open our S3 Backup Bucket my-wordpress-site-backup and get the latest DB backup filename to set our **build.local.properties** file with the s3_backup_url value.

```
s3_backup_url=s3://my-wordpress-site-backup/backup_2017-02-16-1006_My_WP_site_1437f9fb506f-db.gz
```

Let's configure our AWS cli profile using the S3 Bucket user:

```
aws configure --profile=my-wordpress-site
AWS Access Key ID [None]: XXXXXXXXXXXXXXXXXX
AWS Secret Access Key [None]: XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX 
Default region name [None]: eu-central-1
Default output format [None]:
```

And let's rebuild our development environment:

```
AWS_DEFAULT_PROFILE=my-wordpress-site ./vendor/bin/phing setup-dev
```

As you can see now the wp-get-s3-backup get our backup and reinstall our WordPress database with the db-migration target, this enable us to make changes to our WordPress, make a backup and restore its state for all our environments.

Let's do a test, add a page to our WordPress, make a backup, update the build.local.properties with the new WordPress database backup url and run the **setup-dev** phing target.

Now let's continue to set our AWS Elastic BeanStalk environment.

### Creating the EC2 Key Pair

To create your key pair using the Amazon EC2 console

1. Open the Amazon EC2 console at https://console.aws.amazon.com/ec2/.
2. In the navigation pane, under *NETWORK & SECURITY*, choose *Key Pairs*.
3. Enter a name for the new key pair in the Key pair name field of the *Create Key Pair* dialog box, and then choose *Create*.
The private key file is automatically downloaded by your browser. The base file name is the name you specified as the name of your key pair, and the file name extension is *.pem*. Save the private key file in a safe place.
4. If you will use an SSH client on a Mac or Linux computer to connect to your Linux instance, use the following command to set the permissions of your private key file so that only you can read it :

```bash
chmod 400 my-key-pair.pem
```

### Creating the MySQL DB Instance

1. Sign in to the AWS Management Console and open the Amazon RDS console at https://console.aws.amazon.com/rds/.
2. In the top right corner of the Amazon RDS console, choose the region in which you want to create the DB instance.
3. In the navigation pane, choose Instances.
4. Choose Launch DB Instance. The Launch DB Instance Wizard opens on the Select Engine page.
5. On the Select Engine page, choose the MySQL icon and then choose Select for the MySQL DB engine for Dev/Test.
6. On the Specify DB Details page, specify your DB instance information. 
  * DB Instance Class: db.t2.micro
  * Multi-AZ Deployment: No (We are in staging)
  * Allocated Storage: 5 GB
  * Storage Type: Magnetic
  * DB Instance Identifier: staging-my-wordpress-site-db
  * Master Username: wordpress_userdb
  * Master Password: \<YOUR_PASSWORD\>
  * VPC: Select the default VPC
  * Publicly Accessible: No
  * VPC Security Group(s): Create New Security Group 
  * Database Name: staging_my_wordpress_site_db
  * Backup Retention Period: 1
  * Auto Minor Version Upgrade: Yes
7. Click on **Launch DB Instance**

### Set-up your Elastic BeanStalk Application

**To create a new application**

1. Open the Elastic Beanstalk console.
2. Choose Create New Application.
3. Enter the name of the application: **my-wordpress-site** 
4. Then click Create.

### Create your Staging Application Environment 

**To launch an environment** 

1. Open the Elastic Beanstalk console.
2. Choose our application: **my-wordpress-site**
3. In the upper right corner, choose Create New Environment from the Actions menu.
4. Choose **Web server** environment types.
5. For Platform: PHP
6. For App code, choose Sample application.
7. Choose Configure more options.
8. Configuration presets: Custom configuration 
9. Select **Environment settings** and fill in the following:
  *. Name: Staging
  *. Domain: staging-my-wordpress-site
10. Select **Software settings** and fill in the following **Environment properties**:
  * environment: staging
  * MYSQL_ADDON_DB: staging_my_wordpress_site_db 
  * MYSQL_ADDON_HOST: staging-my-wordpress-site-db.ce7wdtyntw8p.\<REGION\>.rds.amazonaws.com
  * MYSQL_ADDON_USER: wordpress_userdb
  * MYSQL_ADDON_PASSWORD: \<YOUR_DB_PASSWORD\>
  * S3_BACKUP_URL: \<YOUR_S3_WORDPRESS_DATABASE_BACKUP\>
  * S3_MEDIA_URL:
11. Optionally if you have configured the WP Security Keys, set the following variables as well:
  * AUTH_KEY:
  * AUTH_SALT:
  * LOGGED_IN_KEY:
  * LOGGED_IN_SALT:
  * NONCE_KEY:
  * NONCE_SALT:
  * SECURE_AUTH_KEY:
  * SECURE_AUTH_SALT:
12. Select **Instances** and fill in the following:
  1. Root volume type: General Purpose (SSD)
  2. Size: 10 GB
13. Select **Security** 
  1. EC2 key pair: \<YOUR_KEY_PAIR\>
14. Select **Notifications**
  1. Email: \<YOUR_EMAIL\>
15. Select **Network**
  1. Select your default VPC in the Virtual private cloud (VPC)
  2. Select all the Instance subnets
  3. Instance security groups select:
  * rds-launch-wizard 
16. Do not configure the Database settings.
17. Choose Create environment.

### Configuring the DocumentRoot

When the environment has been created, let's configure your DocumentRoot.

1. Goto your Elastic Beanstalk application **my-wordpress-site**
2. Select your environment **Staging**
3. Goto Configuration
4. Select **Software Configuration**, and fill in the following:
  * Document root: /wp

Now let's configure the WordPress Site URL.

### Configuring the WordPress Site URL

Still in the **Software Configuration** you will add the SERVER_HOSTNAME variable, but before let's get the URL of our Elastic BeanStalk URL available at the top of the page near the environment name, copy it and add the variable:

* SERVER_HOSTNAME: http://staging-my-wordpress-site.eu-central-1.elasticbeanstalk.com/

Note: if you configure a Route53 alias to your Elastic Load Balancer, use that domain name instead.

### Adding the EC2 Security Group to your RDS Database

In order to let the EC2 communicate with your WordPress RDS Database you need to add the EC2 Security Group to your RDS Database Security Group, for this:

1. Sign-in to the IAM console at https://console.aws.amazon.com/ec2/ with your user that has administrator permissions. 
2. Goto Security Groups
3. Select the rds-launch-wizard Security Group
4. Goto Inbound and Edit
5. Add in Inboud Rule with:
   * Type: MySQL/Aurora
   * Protocol: TCP/IP
   * Port Range: 3306
   * Source: \<EC2_SECURITY_GROUP_ID\>

To find the EC2 Security Group Id, find the Security Group Name called **my-wordpress-site**

## Set up the IAM permissions

Let's create an IAM policy to grant continuousphp the permission to upload the package to your Elastic BeanStalk bucket and communicate with Elastic BeanStalk to deploy it.

**Create the policy**

1. Sign-in to the IAM console at https://console.aws.amazon.com/iam/ with your user that has administrator permissions.
2. In the navigation pane, choose *Policies*.
3. In the content pane, choose *Create Policy*.
4. Next to *Create Your Own Policy*, choose *Select*.
5. As *Policy Name*, type **eb-deploy-staging**.
6. As *Policy Document*, paste the following policy.

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "autoscaling:*",
                "cloudformation:*",
                "ec2:*"
            ],
            "Effect": "Allow",
            "Resource": [
                "*"
            ]
        },
        {
            "Action": [
                "elasticbeanstalk:*"
            ],
            "Effect": "Allow",
            "Resource": [
                "arn:aws:elasticbeanstalk:*::solutionstack/*",
                "arn:aws:elasticbeanstalk:<AWS-REGION>:<AWS-ACCOUNT-ID>:application/my-wordpress-site",
                "arn:aws:elasticbeanstalk:<AWS-REGION>:<AWS-ACCOUNT-ID>:applicationversion/my-wordpress-site/*",
                "arn:aws:elasticbeanstalk:<AWS-REGION>:<AWS-ACCOUNT-ID>:environment/my-wordpress-site/*",
                "arn:aws:elasticbeanstalk:<AWS-REGION>:<AWS-ACCOUNT-ID>:template/my-wordpress-site/*"
            ]
        },
        {
            "Action": [
                "s3:Get*"
            ],
            "Effect": "Allow",
            "Resource": [
                "arn:aws:s3:::elasticbeanstalk-*/*"
            ]
        },
        {
            "Action": [
                "s3:CreateBucket",
                "s3:DeleteObject",
                "s3:GetBucketPolicy",
                "s3:GetObjectAcl",
                "s3:ListBucket",
                "s3:PutBucketPolicy",
                "s3:PutObject",
                "s3:PutObjectAcl"
            ],
            "Effect": "Allow",
            "Resource": [
                "arn:aws:s3:::elasticbeanstalk-<AWS-REGION>-<AWS-ACCOUNT-ID>",
                "arn:aws:s3:::elasticbeanstalk-<AWS-REGION>-<AWS-ACCOUNT-ID>/*"
            ]
        },
        {
            "Action": [
                "iam:PassRole"
            ],
            "Effect": "Allow",
            "Resource": [
                "arn:aws:iam::<AWS-ACCOUNT-ID>:role/aws-elasticbeanstalk-ec2-role"
            ]
        },
        {
            "Action": [
                "elasticloadbalancing:DescribeLoadBalancers"
            ],
            "Effect": "Allow",
            "Resource": [
                "*"
            ]
        },
        {
            "Action": [
                "elasticloadbalancing:RegisterInstancesWithLoadBalancer"
            ],
            "Effect": "Allow",
            "Resource": [
                "arn:aws:elasticloadbalancing:<AWS-REGION>:<AWS-ACCOUNT-ID>:loadbalancer",
                "arn:aws:elasticloadbalancing:<AWS-REGION>:<AWS-ACCOUNT-ID>:loadbalancer/*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": "sns:*",
            "Resource": "arn:aws:sns:<AWS-REGION>:<AWS-ACCOUNT-ID>:*"
        }
    ]
}
```

7\. Choose *Validate Policy* and ensure that no errors display in a red box at the top of the screen. Correct any that are reported.

8\. Choose *Create Policy*.

Now let's create an IAM user with an Access Key and attach the policy we've just created.

**Create a new User and attach the User policy**

1. Sign-in to the Identity and Access Management (IAM) console at https://console.aws.amazon.com/iam/.
2. In the navigation pane, choose *Users* and then choose *Create New Users*.
3. Enter the following user: **staging-wordpress-deploy**
4. Select **Programmatic access** then click Next
5. Select **Attach existing policies directly**
6. Search for the policy we just made: **eb-deploy-staging**
7. Click Next the Create User 
8. Save the generated access key in a safe place.
9. Choose *Close*.

## Set-up continuousphp

### WordPress Project Set-up in continuousphp

**Set-up our WordPress project in continuousphp**

1. Type in the omnibar the name of the application: **wordpress-eb**
2. The fork should appear in the Project List (if not please wait a little that projects list update or simply logout/login)
3. Click on **Setup**
4. Click on **Setup Repository**
5. Click on **+** to add a deployment pipeline
6. Select the **develop** branch

### Deployment pipeline Configuration

**To configure your deployment pipeline**

1. In the Build Settings (Step 1):
   1. In the **PHP VERSIONS**, select the PHP versions: **7.1**
   2. Set the Document Root to: wp
   3. In the **CREDENTIALS**, click on the **+**, add the AWS IAM Credential **deployment.staging** User Access Key and Secret Key we created in step [Set-up the IAM permissions](#set-up-the-iam-permissions)
      * Name: deployment.staging
      * Region: \<SELECT_YOUR_AWS_REGION\>
      * Access Key: \<YOUR_DEPLOYMENT_ACCESS_KEY\>
      * Secret Key: \<YOUR_DEPLOYMENT_SECRET_KEY\> 
   4. Still in the **CREDENTIALS**, click on the **+**, add the AWS IAM Credential **my-wordpress-site-backup** User Access Key and Secret Key we created in step [Set-up the WordPress backup S3 bucket IAM policy](#set-up-the-wordpress-backup-s3-bucket-iam-policy)
      * Name: my-wordpress-site-backup
      * Region: \<SELECT_YOUR_AWS_REGION\>
      * Access Key: \<YOUR_SITE_BACKUP_ACCESS_KEY\> 
      * Secret Key: \<YOUR_SITE_BACKUP_SECRET_KEY\>
   5. In the **PHING** section, add the following Phing Target: **wp-composer-plugins-update**
   6. Uncheck the **Enable caching of Composer packages**
   6. Click on **Next** to move to the Test Settings
2. In the Test Settings (Step 2):
   1. continuousphp automatically discovers that you have a `behat.yml` and `phpunit.xml` in your repository and creates the testing configuration for you.
   2. Click on the **Behat** configuration panel. In the **PHING** section, select the following Phing Targets: **reset-db** and **setup-test**
   3. Still in the **PHING** section, add the following variables:
      * environment: develop
   4. Set the environment variables, Click on the + Next to **ENVIRONMENT VARIABLES**
      * MYSQL_ADDON_HOST: 127.0.0.1
      * MYSQL_ADDON_DB: wordpress
      * MYSQL_ADDON_USER: root
      * MYSQL_ADDON_PASSWORD:
      * S3_BACKUP_URL:  \<YOUR_S3_WORDPRESS_DATABASE_BACKUP\> 
      * S3_MEDIA_URL:
      * SERVER_HOSTNAME: http://localhost/
      * AUTH_KEY:
      * AUTH_SALT:
      * SECURE_AUTH_KEY:
      * LOGGED_IN_KEY:
      * NONCE_KEY:
      * SECURE_AUTH_SALT:
      * LOGGED_IN_SALT:
      * NONCE_SALT:
   5. Click on **Next** to move to the Package Settings
3. In the Package Settings (Step 3):
   1. Select **AWS ElasticBeanstalk**
   2. In the **PHING** section, add the following Phing Target: **wp-composer-plugins-update**
   3. Click on **Next** to move to the Deployment Settings
4. In the Deployment Settings (Step 4):
   1. Click on **+** on the **DESTINATIONS** panel
   2. Complete the destination:
      * Name: staging
      * Apply to: push
      * IAM Profile: The profile we created in Step 1.2
      * Application: my-wordpress-site 
      * Environment: Staging
      * S3 Bucket: Sign-in to the AWS Management Console and open the Amazon S3 console at https://console.aws.amazon.com/s3, look for a bucket called elasticbeanstalk-\<AWS-REGION\>-\<AWS-ACCOUNT-ID\> and add **/package**
   3. Check the **enable deployment for successful builds** checkbox

## Deploying WordPress

Before Deploying, let's push our changes:

```
git status
git add build.properties
git add composer.json
git add tests/features/homepage.feature
git commit -m "Adding plugins and behat tests"
git push origin develop
```

A build has started automatically on continuousphp.

**Deploying WordPress manually with continuousphp**

1. Click on the **Play** button on the top right of the project
2. Select the **develop** branch
3. The build is started. It will create the testing and dist package, then run the tests (Behat) for the choosen PHP versions, and finally it deploys the WordPress on Elastic BeanStalk Staging environment.
4. In the deploy console, you should see **Deployment successfully started**
5. Login to the AWS console/AWS Elastic BeanStalk to see the details.

Let's modify our Dumy plugin at ./wp-content/plugins/dumy-plugin/dumy-plugin.php and bump its version to 1.1: 

```
<?php
    /*
    Plugin Name: dumy-plugin
    Plugin URI:
    Description: A Dumy plugin
    Author: John Doe
    Version: 1.1
    Author URI: https://www.johndoe-dumy-plugin.com
    */
?>
```

```bash
git checkout develop
git add ./wp-content/plugins/dumy-plugin/dumy-plugin.php
git commit -m "Bumping our Dumy plugin version"
git pusih origin develop
```

Now, everytime you push to the develop branch, your develop pipeline is triggered and continuousphp builds, tests and deploys your WordPress upon a successful build.

## Notes

* The Configuration used in this tutorial is an example and should not be used for production use as is.
* The Configuration used in this tutorial is a base and should be completed to suit your needs.
* This Tutorials used AWS Resources which has cost, please delete your Elastic BeanStalk and RDS database when you have finished to avoid cost.

If you like to know more about production configuration or have questions about this tutorial, do not hesitate to contact us using the chat button!
