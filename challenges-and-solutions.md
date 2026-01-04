## 🚧 Challenges & ✅ Solutions
## Challenge 1️⃣ : Risk of AWS Credit Exhaustion and Work Loss
**Context:**  
While working on AWS, we noticed that the available free credit was about to run out. If this happened, instances and ongoing data could be stopped or deleted, resulting in potential loss of work.

**Implemented Solution:**  
- Regularly back up critical data to an **S3 bucket** to prevent data loss.  
- Create an **AMI (Amazon Machine Image)** of each instance to restore its full state in case of deletion.

✅ This ensures that even if AWS credit runs out, we can restore the environment and continue the project without losing data.

---

## Challenge 2️⃣ : Storage Space Saturation for Backups
**Context:**  
When backing up volumes or data on the EC2 instance, we noticed that the disk space was full, preventing new backups from being created.

**Possible Solutions:**  
1. **Delete unnecessary files or logs** on the instance to free up space.  
2. **Increase the EC2 instance EBS volume size** to have more space for backups.

💡 **Recommendation:** We can combine both approaches: clean up temporary or unnecessary logs to optimize space, then increase the volume if needed to anticipate future storage requirements.