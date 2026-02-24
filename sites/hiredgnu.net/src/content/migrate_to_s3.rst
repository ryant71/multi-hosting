Migrating This Website To S3
============================

:date: 2025-03-29 12:00:00
:tags: AWS, S3, Cloudfront, Cloudformation
:category: tech
:author: Ryan Tracey
:slug: migrating-website-to-s3
:summary: Migrating this site to S3

.. _Linode: https://linode.com/


Setting up the TLS certificate
------------------------------

We use Cloudformation for this, and make a separate template. The reason
being that the certificate has to be created in the `us-east-1` region
rather then the region I want to keep the rest of the resources in.

I deploy the stack with:

.. code-block:: bash

    aws --region us-east-1 cloudformation create-stack \
        --stack-name hiredgnu-certificate \
        --template-body file://certificate.yml

The template is:

.. code-block:: yaml

    AWSTemplateFormatVersion: '2010-09-09'

    Parameters:
      DomainName:
        Type: String
        Description: The domain name for the website
        Default: hiredgnu.net 

    Resources:
      Certificate:
        Type: 'AWS::CertificateManager::Certificate'
        Properties:
          DomainName: !Ref DomainName
          SubjectAlternativeNames:
            - !Sub "*.${DomainName}"
          DomainValidationOptions:
            - DomainName: !Ref DomainName
              HostedZoneId: Z2B00DRLLVN6P9
          ValidationMethod: DNS

    Outputs:
      CertificateArn:
        Description: Issued SSL certificate Arn
        Value: !Ref Certificate

Setting up the S3 Bucket, CloudFront Distribution, and DNS records
------------------------------------------------------------------

I deploy the stack with:

.. code-block:: bash

    aws --region eu-west-1 cloudformation create-stack \
        --stack-name hiredgnu-s3-web \
        --template-body file://s3.yml


The template is:

.. code-block:: yaml

    AWSTemplateFormatVersion: '2010-09-09'

    Parameters:
      DomainName:
        Type: String
        Description: The domain name for the website
        Default: hiredgnu.net 

      FQDN:
        Type: String
        Description: The fqdn name for the website
        Default: hiredgnu.net 

      CertificateArn:
        Type: String
        Default: arn:aws:acm:us-east-1:MY-ACCOUNT-ID:certificate/CERTIFICATEID
        Description: The ARN of the ACM certificate created in us-east-1

    Resources:
      S3Bucket:
        Type: 'AWS::S3::Bucket'
        Properties:
          BucketName: !Ref FQDN
          PublicAccessBlockConfiguration:
            BlockPublicAcls: false
            BlockPublicPolicy: false
            IgnorePublicAcls: false
            RestrictPublicBuckets: false
          WebsiteConfiguration:
            IndexDocument: index.html
            ErrorDocument: error.html
        DeletionPolicy: Retain
        UpdateReplacePolicy: Retain

      BucketPolicy:
        Type: 'AWS::S3::BucketPolicy'
        Properties:
          PolicyDocument:
            Id: MyPolicy
            Version: 2012-10-17
            Statement:
              - Sid: PublicReadForGetBucketObjects
                Effect: Allow
                Principal: '*'
                Action: 's3:GetObject'
                Resource: !Sub "arn:aws:s3:::${S3Bucket}/*"
          Bucket: !Ref S3Bucket

      CloudFrontDistribution:
        Type: AWS::CloudFront::Distribution
        Properties:
          DistributionConfig:
            Aliases:
              - !Ref FQDN
            Origins:
              - Id: S3Origin
                DomainName: !Sub "${FQDN}.s3-website-eu-west-1.amazonaws.com"
                CustomOriginConfig:
                  HTTPPort: 80
                  HTTPSPort: 80
                  OriginProtocolPolicy: http-only
            Enabled: true
            DefaultCacheBehavior:
              TargetOriginId: S3Origin
              ViewerProtocolPolicy: redirect-to-https
              AllowedMethods:
                - GET
                - HEAD
              CachedMethods:
                - GET
                - HEAD
              ForwardedValues:
                QueryString: false
                Cookies:
                  Forward: none
            ViewerCertificate:
              AcmCertificateArn: !Ref CertificateArn
              SslSupportMethod: sni-only
            DefaultRootObject: index.html
            PriceClass: PriceClass_100

      DNSRecord:
        Type: AWS::Route53::RecordSet
        Properties:
          HostedZoneName: !Sub "${DomainName}."
          Name: !Ref FQDN 
          Type: A
          AliasTarget:
            DNSName: !GetAtt CloudFrontDistribution.DomainName
            HostedZoneId: Z2FDTNDATAQYW2 # CloudFront hosted zone ID

    Outputs:
      S3BucketWebsiteURL:
        Description: URL for website hosted on S3
        Value: !GetAtt S3Bucket.WebsiteURL

      S3BucketRegionalDomainName:
        Description: Regional domain name for bucket
        Value: !GetAtt S3Bucket.RegionalDomainName 

      CertificateArn:
        Description: Certificate deployed in us-east-1
        Value: !Ref CertificateArn

      CloudFrontDistributionDomainName:
        Description: CloudFront Distribution Domain Name
        Value: !GetAtt CloudFrontDistribution.DomainName

      CloudFrontDistributionId:
        Description: CloudFront Distribution ID
        Value: !Ref CloudFrontDistribution

      S3BucketName:
        Description: S3 Bucket Name
        Value: !Ref S3Bucket


Deploy the site to S3 using the Pelican Makefile and AWS CLI
------------------------------------------------------------

Make the static site from the updated RST files:

.. code-block:: bash

    make html

Upload the generated static files:
    
.. code-block:: bash

    aws s3 sync output/ s3://hiredgnu.net/ --delete

Invalidate the Cloudfront cache:

.. code-block:: bash

    aws cloudfront create-invalidation \
        --distribution-id <DISTRIBUTIONID> \
        --paths "/*"


NOTE: There is a glaring security problem with this implementation. Can you
guess what it is? See my next post for details.

