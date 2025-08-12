# SalesMaster & TeamHub Developer Onboarding

Welcome to the SalesMaster & TeamHub development team! This document is designed to help you quickly get up to speed with our project, understand its structure, and set up your local development environment. Our goal is to provide a seamless experience for sales teams and enhance internal collaboration.

## 1. Introduction

This document serves as your primary guide for onboarding as a developer on the 'SalesMaster & TeamHub' project. It covers everything from setting up your development environment to understanding our coding standards and deployment processes. Please read it thoroughly and don't hesitate to ask questions if anything is unclear.

## 2. Getting Started

To begin contributing, you'll need to set up your development environment. Follow these steps:

### Prerequisites

-   **Git**: Version control system.
-   **Node.js**: Version 18.x or higher (LTS recommended).
-   **Yarn**: Package manager (preferred over npm). Install with `npm install -g yarn`.
-   **Docker & Docker Compose**: For running local database instances and other services.
-   **Expo CLI**: For mobile app development. Install with `yarn global add expo-cli`.

### Setup Steps

1.  **Clone the Repository**:
    ```bash
    git clone https://github.com/your-org/salesmaster-teamhub.git
    cd salesmaster-teamhub
    ```
2.  **Install Dependencies**: Each project within the monorepo has its own dependencies. You'll install them separately.
3.  **Environment Variables**: Each project requires specific environment variables. Look for `.env.example` files in each project directory (`backend/`, `web-admin/`, `mobile/`), copy them to `.env`, and fill in the necessary values.

## 3. Repository Overview

The SalesMaster & TeamHub project is structured as a monorepo, containing several distinct applications and services. Here's a breakdown of the main directories:

-   `mobile/`: Contains the React Native/Expo mobile application for sales representatives and team members.
-   `web-admin/`: Houses the Next.js web application for administrative tasks, reporting, and team management.
-   `backend/`: The NestJS API backend, serving data to both mobile and web applications. This is where the core business logic resides.
-   `infra/`: Infrastructure-as-Code configurations (e.g., Docker Compose files for local development, potentially Terraform/CloudFormation for cloud deployments).
-   `scripts/`: Various utility scripts for development, testing, and deployment automation.
-   `docs/`: Project documentation, including this onboarding guide.

## 4. Development Workflow

### Branching Strategy

We follow a GitFlow-like branching model to manage our codebase:

-   `main`: Represents the production-ready code. Only stable, tested releases are merged here.
-   `develop`: The latest integrated development code. All new features and bug fixes are merged into `develop` before being released.
-   `feature/<feature-name>`: Created from `develop` for developing new features. Merged back into `develop` upon completion.
-   `release/<version>`: Created from `develop` when preparing for a new release. Used for final bug fixes and release-specific tasks. Merged into `main` and `develop` after release.
-   `hotfix/<bug-name>`: Created from `main` for urgent bug fixes in production. Merged back into `main` and `develop` upon completion.

### Commit Message Style

We adhere to the Conventional Commits specification for clear and automated changelog generation. Each commit message should follow the format: `<type>(<scope>): <description>`.

-   **Types**:
    -   `feat`: A new feature.
    -   `fix`: A bug fix.
    -   `docs`: Documentation only changes.
    -   `style`: Changes that do not affect the meaning of the code (white-space, formatting, missing semicolons, etc.).
    -   `refactor`: A code change that neither fixes a bug nor adds a feature.
    -   `test`: Adding missing tests or correcting existing tests.
    -   `chore`: Other changes that don't modify src or test files (e.g., build process, auxiliary tools, libraries).
    -   `perf`: A code change that improves performance.
    -   `ci`: Changes to our CI configuration files and scripts.
    -   `build`: Changes that affect the build system or external dependencies.
-   **Scope (Optional)**: The part of the codebase affected (e.g., `backend`, `web-admin`, `mobile-auth`).
-   **Description**: A concise summary of the change.

**Examples**:
-   `feat(backend): Implement user authentication endpoint`
-   `fix(mobile): Correct login form validation error`
-   `docs: Update README with new setup instructions`
-   `chore(deps): Upgrade NestJS to v9`

## 5. Running the Applications

You can run each part of the project independently or together. Ensure your environment variables are configured for each project.

### Backend (NestJS)

1.  Navigate to the backend directory:
    ```bash
    cd backend
    ```
2.  Install dependencies:
    ```bash
    yarn install
    ```
3.  Copy and configure environment variables:
    ```bash
    cp .env.example .env
    # Edit .env to configure database connection, JWT secrets, etc.
    ```
4.  Start the local database (PostgreSQL via Docker Compose):
    ```bash
    docker-compose up -d db
    ```
5.  Run database migrations (if any):
    ```bash
    yarn typeorm migration:run
    ```
6.  Start the backend in development mode:
    ```bash
    yarn start:dev
    ```
    The API will typically be available at `http://localhost:3000`.

### Web Admin (Next.js)

1.  Navigate to the web-admin directory:
    ```bash
    cd web-admin
    ```
2.  Install dependencies:
    ```bash
    yarn install
    ```
3.  Copy and configure environment variables:
    ```bash
    cp .env.example .env
    # Edit .env to point to your local backend API (e.g., NEXT_PUBLIC_API_URL=http://localhost:3000)
    ```
4.  Start the web admin application:
    ```bash
    yarn dev
    ```
    The web admin will typically be available at `http://localhost:3001`.

### Mobile App (React Native/Expo)

1.  Navigate to the mobile directory:
    ```bash
    cd mobile
    ```
2.  Install dependencies:
    ```bash
    yarn install
    ```
3.  Copy and configure environment variables:
    ```bash
    cp .env.example .env
    # Edit .env to point to your local backend API (e.g., EXPO_PUBLIC_API_URL=http://192.168.X.X:3000 - use your local IP for physical devices)
    ```
4.  Start the Expo development server:
    ```bash
    yarn start
    ```
    This will open a new browser tab with the Expo Dev Tools. You can then:
    -   Scan the QR code with the Expo Go app on your physical device.
    -   Press `a` to open on an Android emulator.
    -   Press `i` to open on an iOS simulator.

## 6. Testing

We maintain a strong testing culture to ensure code quality and stability.

-   **Unit Tests**: Test individual functions, components, or services in isolation.
    -   Run for a specific project (e.g., `backend`): `cd backend && yarn test`
-   **Integration Tests**: Verify that different modules or services work correctly together.
    -   Run for a specific project (e.g., `backend`): `cd backend && yarn test:e2e`
-   **End-to-End (E2E) Tests**: Simulate user interactions with the full application stack. (Details on specific E2E frameworks like Cypress for web or Detox for mobile will be provided separately if applicable).

Always run relevant tests before submitting a pull request.

## 7. Code Conventions

Consistency is key for maintainable code. We enforce code standards using ESLint and Prettier.

-   **General**:
    -   Run `yarn lint` and `yarn format` (or `yarn format:fix`) in each project before committing.
    -   Follow the `.editorconfig` settings.
-   **TypeScript/JavaScript**:
    -   Strict typing is enforced. Use `any` sparingly and with justification.
    -   Consistent naming conventions (camelCase for variables/functions, PascalCase for components/classes).
    -   Avoid deeply nested structures.
-   **React (for `web-admin` and `mobile`)**:
    -   Prefer functional components and React Hooks.
    -   Keep components small and focused on a single responsibility.
    -   Use prop-types or TypeScript interfaces for component props.
    -   Consistent folder structure for components (e.g., `components/Button/index.tsx`).
-   **NestJS (for `backend`)**:
    -   Adhere to NestJS's modular architecture (modules, controllers, services, providers).
    -   Use DTOs (Data Transfer Objects) for request validation and clear API contracts.
    -   Follow the official NestJS style guide.

## 8. API & Database

### API Specification

The backend exposes a RESTful API built with NestJS.
-   API documentation (Swagger/OpenAPI) is automatically generated and available at `http://localhost:3000/api` when the backend is running in development mode. This is your go-to resource for understanding available endpoints, request/response schemas, and authentication requirements.

### Database Schema

-   We use **PostgreSQL** as our primary database.
-   **TypeORM** is used as the Object-Relational Mapper (ORM) in the backend.
-   Database schema changes are managed through TypeORM migrations. When making schema changes, ensure you generate a new migration:
    ```bash
    cd backend
    yarn typeorm migration:generate src/database/migrations/<MigrationName>
    ```
    Then, review and apply it: `yarn typeorm migration:run`.

## 9. CI/CD

Our Continuous Integration and Continuous Deployment (CI/CD) pipeline is powered by **GitHub Actions**.

-   **Automated Tests**: Every push to a feature branch and every pull request triggers automated linting, formatting checks, and unit/integration tests across all projects.
-   **Code Quality**: Tools like ESLint and Prettier are run to ensure code quality and adherence to standards.
-   **Automated Deployments**:
    -   Merges to `develop` trigger deployments to our staging environment.
    -   Merges to `main` (typically from a `release` branch) trigger deployments to our production environment.

You can monitor the status of builds and deployments directly from the "Actions" tab in our GitHub repository.