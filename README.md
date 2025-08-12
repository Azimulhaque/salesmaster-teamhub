# SalesMaster & TeamHub

A comprehensive mobile-first SaaS platform to unify sales, customer KYC, field attendance, and employee engagement.

## Overview

SalesMaster & TeamHub is a powerful application designed to streamline sales processes, manage customer relationships, track field employee attendance, and foster a more engaged and connected workforce. By integrating these key functions into a single, intuitive platform, we aim to boost productivity, improve communication, and enhance overall business efficiency.

This repository contains the full source code for the mobile applications (iOS & Android), web admin panels, backend services, and infrastructure definitions.

## Features

*   **Sales & CRM:** Log customer visits, manage KYC data, and track interactions.
*   **Task & Reminder Management:** Never miss a follow-up, birthday, or anniversary with intelligent reminders.
*   **Attendance Tracking:** Monitor field employee check-ins and check-outs with geolocation.
*   **Employee Engagement:** Keep your team connected with an employee directory and personal milestone alerts.
*   **Real-Time Notifications:** Instant alerts via push, email, and SMS for important events.
*   **Powerful Admin Panels:** Configure and manage the entire system through a comprehensive web interface.

## Tech Stack

*   **Mobile:** React Native (Expo)
*   **Web Admin:** Next.js + Chakra UI
*   **Backend:** Node.js + NestJS (REST & GraphQL)
*   **Database:** PostgreSQL + Redis
*   **Real-Time:** Socket.io
*   **Infrastructure:** Docker, Kubernetes (EKS), Terraform
*   **CI/CD:** GitHub Actions

## Getting Started

**Prerequisites:**

*   Node.js
*   Docker
*   Git

**Installation:**

1.  Clone the repository:
    ```bash
    git clone https://github.com/Azimulhaque/salesmaster-teamhub.git
    ```
2.  Navigate to the project directory:
    ```bash
    cd salesmaster-teamhub
    ```
3.  Follow the setup instructions in the `docs/` folder.

## Repository Structure

```
salesmaster-teamhub/
├── mobile/         # React Native (Expo) mobile app
├── web-admin/      # Next.js admin dashboard
├── backend/        # NestJS backend services
├── infra/          # Terraform & Kubernetes manifests
├── scripts/        # CI/CD pipelines & test scripts
├── docs/           # Documentation, diagrams, API specs
└── README.md
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
