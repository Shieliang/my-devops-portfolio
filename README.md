# ☁️ Cloud DevOps Portfolio: IaC, CI/CD & Observability

Live Demo: [https://d16uuu8qayhp8j.cloudfront.net/](https://d16uuu8qayhp8j.cloudfront.net/)

## 📖 Overview
Welcome to my cloud portfolio! This repository is not just a static website; it is a **fully automated, secure, and observable Cloud Infrastructure showcase**. 

As an **AWS Certified Cloud & AI Practitioner** looking for Junior Cloud/DevOps roles in Kuala Lumpur, I built this project to demonstrate hands-on expertise in provisioning cloud resources, automating deployments, and monitoring system health across environments.

## 🏗️ Architecture & Data Flow

This project is built on three core DevOps pillars:

1. **Infrastructure as Code (IaC):** Automated provisioning of AWS S3 and CloudFront using **Terraform**.
2. **Continuous Integration & Delivery (CI/CD):** A **GitHub Actions** pipeline automatically syncs code to S3 and invalidates the CloudFront cache upon every `git push`.
3. **Observability (Monitoring Stack):** * A local **Docker Compose** stack (Prometheus + Grafana).
   * A Linux `cron` job runs a Bash script every 5 minutes to fetch CloudFront metrics from **AWS CloudWatch** and pushes them to a local **Pushgateway**.

## ⚙️ Tech Stack

* **Cloud Provider:** AWS (S3, CloudFront, CloudWatch, IAM)
* **Infrastructure as Code:** Terraform
* **CI/CD Automation:** GitHub Actions, Bash Scripting
* **Observability:** Docker, Prometheus, Pushgateway, Grafana, Linux Cron
* **Frontend:** HTML5, CSS3, FontAwesome

## ✨ Key Security & Engineering Highlights

* **🔒 Enterprise-Grade Security (OAC):** Moved away from outdated S3 public website hosting. Implemented **Origin Access Control (OAC)** and strictly configured S3 Bucket Policies to block all public access. The origin is strictly private and only accessible via the CloudFront CDN.
* **⚡ Zero-Touch Deployment:** Created a custom local `push.sh` script with safety checks. Code changes are automatically pushed, deployed, and cached globally within 2 minutes.
* **📊 Cross-Environment Monitoring:** Solved the challenge of monitoring cloud metrics locally by bridging AWS CloudWatch with a Dockerized Prometheus stack via `curl` and Pushgateway.

## 👨‍💻 About the Author

**Shie Liang Yong**
* AWS Certified Cloud Practitioner | AWS Certified AI Practitioner
* Passionate about Cloud Infrastructure, GenAI (RAG), and solving the classic *"It works on my machine"* dilemma.
* 📍 Open to Junior Cloud, DevOps, or AI Engineer opportunities in Kuala Lumpur.

🔗 [LinkedIn](https://www.linkedin.com/in/shie-liang-yong) | 🔗 [AWS Builder Profile](https://community.aws/@shieliang22)