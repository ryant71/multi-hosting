Secure an S3 Hosted Website
===========================

:date: 2025-03-30 12:00:00
:tags: AWS, S3, Cloudfront, Cloudformation
:category: tech
:author: Ryan Tracey
:slug: make-s3-website-more-secure
:summary: Make the S3 website hosting more secure

In my `previous post <{filename}/migrate_to_s3.rst>`_, I set up a website on S3 with CloudFront for TLS and
caching.

However, that implementation left my AWS account open to a specific type of
attack.

"S3 request amplification" or "unintended request charging", can occur when
an S3 bucket is misconfigured to allow public access or does not properly
block unauthorized requests.

Say, I have ``my-bucket.s3.amazonaws.com/logo.png`` hosted on S3. An attacker
can embed this URL on a high-traffic site as follows:

``<img src="https://my-bucket.s3.amazonaws.com/logo.png">``

With each connection to that page, a GET is made to my S3 bucket which I
ultimately pay for.

The solutions could include:

* Blocking public access at the account or bucket level unless explicitly required

* Use signed URLs for any external access

* Enable request logging to spot abuse early

* Set up CloudWatch alarms for unusual request rates or costs

* Use AWS WAF or CloudFront with throttling and domain filtering

* Apply strict bucket policies to limit access by IP or AWS Principal

To accomplish some of the above I made the following changes to my Cloudformation template.

.. image:: /images/diff.png
   :alt: Screenshot of diff between insecure and secure template
   :width: 700px

Note: The screenshot of the diff contains an error an error... There is a
missing ``!GetAtt`` somewhere...

Okay, enough guessing it's ``!GetAtt CloudFrontDistribution.DomainName``.

The complete template
---------------------

.. code-block:: yaml

    AWSTemplateFormatVersion: '2010-09-09'

    Parameters:
      DomainName:
        Type: String
        Description: The domain name for the website (e.g., example.com)
        Default: hiredgnu.net 

      FQDN:
        Type: String
        Description: The fqdn name for the website (e.g., blog.example.com)
        Default: hiredgnu.net 

      CertificateArn:
        Type: String
        Description: The ARN of the ACM certificate created in us-east-1

    Resources:
      S3Bucket:
        Type: 'AWS::S3::Bucket'
        Properties:
          BucketName: !Ref FQDN
          PublicAccessBlockConfiguration:
            BlockPublicAcls: true
            BlockPublicPolicy: true
            IgnorePublicAcls: true
            RestrictPublicBuckets: true
          WebsiteConfiguration:
            IndexDocument: index.html
            ErrorDocument: error.html
        DeletionPolicy: Retain
        UpdateReplacePolicy: Retain

      BucketPolicy:
        Type: 'AWS::S3::BucketPolicy'
        Properties:
          Bucket: !Ref S3Bucket
          PolicyDocument:
            Version: 2012-10-17
            Statement:
              - Effect: Allow
                Principal:
                  Service: cloudfront.amazonaws.com
                Action: s3:GetObject
                Resource: !Sub "arn:aws:s3:::${S3Bucket}/*"
                Condition:
                  StringEquals:
                    AWS:SourceArn: !Sub "arn:aws:cloudfront::${AWS::AccountId}:distribution/${CloudFrontDistribution}"

      CloudFrontOAC:
        Type: AWS::CloudFront::OriginAccessControl
        Properties:
          OriginAccessControlConfig:
            Name: !Sub "${FQDN}-OAC"
            OriginAccessControlOriginType: s3
            SigningBehavior: always
            SigningProtocol: sigv4

      CloudFrontDistribution:
        Type: AWS::CloudFront::Distribution
        Properties:
          DistributionConfig:
            Aliases:
              - !Ref FQDN
            Origins:
              - Id: S3Origin
                DomainName: !GetAtt S3Bucket.RegionalDomainName
                S3OriginConfig: {}
                OriginAccessControlId: !Ref CloudFrontOAC
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
              Compress: true
              CachePolicyId: 658327ea-f89d-4fab-a63d-7e88639e58f6 # CachingOptimised
              OriginRequestPolicyId: 88a5eaf4-2fd4-4709-b370-b4c650ea3fcf # None (no headers/cookies/query strings)
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
