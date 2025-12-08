# AWS Elastic Beanstalk Deployment Guide

## Prerequisites

1. **AWS Account** with Elastic Beanstalk access
2. **RDS PostgreSQL Database** (or use existing PostgreSQL instance)
3. **S3 Bucket** (optional but recommended for image storage)
4. **AWS CLI** installed and configured (optional, for EB CLI)

## Step 1: Set Up AWS RDS PostgreSQL Database

1. Go to AWS Console → RDS → Create Database
2. Choose **PostgreSQL**
3. Configuration:
   - **DB Instance Identifier**: `is-event-calendar-db`
   - **Master Username**: `postgres` (or your choice)
   - **Master Password**: Create a strong password
   - **DB Instance Class**: `db.t3.micro` (free tier) or larger
   - **Storage**: 20 GB minimum
   - **VPC**: Use default VPC
   - **Public Access**: Yes (or configure VPC security groups)
   - **Database Name**: `eventcalendar` (or your choice)

4. **Important**: Note down:
   - Endpoint (e.g., `your-db.xxxxxxxx.us-east-1.rds.amazonaws.com`)
   - Port (usually `5432`)
   - Username and Password

5. **Security Groups**: Ensure your RDS security group allows inbound traffic from your Elastic Beanstalk environment on port 5432

## Step 2: Create S3 Bucket for Image Storage (Recommended)

1. Go to AWS Console → S3 → Create Bucket
2. Configuration:
   - **Bucket Name**: `is-event-calendar-uploads` (must be globally unique)
   - **Region**: Same as your Elastic Beanstalk environment
   - **Block Public Access**: Uncheck "Block all public access" if you want public image URLs
   - **Bucket Policy**: Add policy to allow public read access (if needed)

3. **Bucket Policy Example** (for public read):
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PublicReadGetObject",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::is-event-calendar-uploads/*"
    }
  ]
}
```

4. **IAM User for S3 Access**:
   - Create IAM user with programmatic access
   - Attach policy: `AmazonS3FullAccess` (or create custom policy)
   - Save Access Key ID and Secret Access Key

## Step 3: Deploy to Elastic Beanstalk

### Option A: Using AWS Console (Web UI)

1. Go to AWS Console → Elastic Beanstalk → Create Application
2. Application Details:
   - **Application Name**: `is-event-calendar`
   - **Platform**: Node.js
   - **Platform Branch**: Node.js 18 (or latest)
   - **Platform Version**: Latest
   - **Application Code**: Upload your code (zip file)

3. **Configure More Options**:
   - **Environment Type**: Single instance (for testing) or Load balanced (for production)
   - **Capacity**: Auto Scaling (recommended for production)

4. **Software Configuration** → Environment Properties:
   Add the following environment variables:
   ```
   DB_HOST=your-rds-endpoint.xxxxxxxx.us-east-1.rds.amazonaws.com
   DB_USER=postgres
   DB_PASSWORD=your-database-password
   DB_NAME=eventcalendar
   DB_PORT=5432
   SESSION_SECRET=your-very-long-random-secret-key-here
   PORT=8081
   NODE_ENV=production
   
   # S3 Configuration (if using S3 for images)
   AWS_ACCESS_KEY_ID=your-aws-access-key-id
   AWS_SECRET_ACCESS_KEY=your-aws-secret-access-key
   AWS_REGION=us-east-1
   S3_BUCKET_NAME=is-event-calendar-uploads
   ```

5. Click **Create Environment**

### Option B: Using EB CLI

1. Install EB CLI:
```bash
pip install awsebcli
```

2. Initialize EB:
```bash
eb init -p node.js -r us-east-1
```

3. Create Environment:
```bash
eb create is-event-calendar-prod
```

4. Set Environment Variables:
```bash
eb setenv DB_HOST=your-rds-endpoint.xxxxxxxx.us-east-1.rds.amazonaws.com \
         DB_USER=postgres \
         DB_PASSWORD=your-database-password \
         DB_NAME=eventcalendar \
         DB_PORT=5432 \
         SESSION_SECRET=your-very-long-random-secret-key \
         PORT=8081 \
         NODE_ENV=production
```

5. Deploy:
```bash
eb deploy
```

## Step 4: Set Up Database Schema

1. Connect to your RDS instance using pgAdmin or psql
2. Run the `database_setup_complete.sql` script
3. Verify tables are created

## Step 5: Configure Security Groups

1. **RDS Security Group**:
   - Add inbound rule: PostgreSQL (port 5432) from your EB security group

2. **EB Security Group**:
   - Ensure HTTP (80) and HTTPS (443) are open
   - Allow outbound to RDS on port 5432

## Step 6: Update Code for S3 (Optional but Recommended)

**Current Limitation**: The app uses local file storage which won't persist on EB instances.

**Recommended**: Implement S3 upload as discussed earlier. For now, images will be lost when instances restart/replace.

To implement S3:
1. Install AWS SDK: `npm install aws-sdk multer-s3`
2. Update `index.js` to use S3 storage (see earlier discussion)

## Important Notes

### Current Deployment Limitations:
- ⚠️ **Image Uploads**: Currently stored locally - will be lost on instance replacement
- ⚠️ **Sessions**: Using in-memory storage - may cause issues with multiple instances

### Production Recommendations:
1. ✅ **Use S3 for images** (implement as discussed)
2. ✅ **Use database sessions** or Redis for session storage
3. ✅ **Enable HTTPS** (EB can auto-configure with ACM certificate)
4. ✅ **Set up monitoring** with CloudWatch
5. ✅ **Configure auto-scaling** based on load
6. ✅ **Set up backups** for RDS database

## Troubleshooting

### Database Connection Issues
- Check RDS security group allows EB security group
- Verify environment variables are set correctly
- Check RDS endpoint is correct

### Application Won't Start
- Check EB logs: `eb logs` or in AWS Console
- Verify PORT environment variable is set
- Check Node.js version compatibility

### Image Upload Failures
- Verify uploads directory exists (created automatically)
- Check file size limits (currently 5MB)
- For production, implement S3 storage

## Environment Variables Reference

| Variable | Description | Example |
|----------|-------------|---------|
| DB_HOST | RDS endpoint | `db.xxxxx.us-east-1.rds.amazonaws.com` |
| DB_USER | Database username | `postgres` |
| DB_PASSWORD | Database password | `your-secure-password` |
| DB_NAME | Database name | `eventcalendar` |
| DB_PORT | Database port | `5432` |
| SESSION_SECRET | Random secret for sessions | `generate-random-string` |
| PORT | Application port | `8081` (EB default) |
| NODE_ENV | Environment | `production` |

## Cost Estimates (AWS Free Tier Eligible)

- **Elastic Beanstalk**: Free (only pay for EC2 instances)
- **EC2 t3.micro**: Free tier eligible (750 hours/month)
- **RDS db.t3.micro**: Free tier eligible (750 hours/month)
- **S3 Storage**: First 5GB free, then ~$0.023/GB/month
- **Data Transfer**: First 1GB/month free

**Total Estimated Cost**: $0-15/month (depending on usage)

