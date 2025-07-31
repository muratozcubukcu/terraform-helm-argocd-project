# 🚀 Terrahelm Web Application

A comprehensive monitoring and testing web application for your Terrahelm deployment. This Node.js application provides real-time insights into your frontend, backend, and database connectivity.

## ✨ Features

### 🔍 **Real-time Monitoring**
- **Frontend Status**: Pod information, memory usage, uptime, Node.js version
- **Backend Status**: PostgreSQL connectivity, response times, database metrics
- **System Information**: Kubernetes environment details, resource usage
- **Auto-refresh**: Updates every 30 seconds automatically

### 🧪 **Interactive Testing**
- **Database Write Tests**: Test PostgreSQL write operations
- **Connection Health Checks**: Verify database connectivity
- **Recent Activity Logs**: View recent health check history
- **Real-time Feedback**: Live logging of test results

### 📊 **Key Metrics Displayed**
- Pod name, namespace, node, and IP address
- Application uptime and memory usage
- Database size and connection pool status
- Response times and health check counts
- Recent database activity history

## 🌐 **Web Interface**

The application provides a beautiful, responsive web interface accessible at:
- **Production**: `http://your-service-url/`
- **Local**: `http://localhost:3000/`

### 🎨 **Interface Components**
- **Frontend Status Card**: Shows pod and application information
- **Backend Status Card**: Displays database connectivity and metrics
- **System Information Card**: Kubernetes and system details
- **Database Test Section**: Interactive testing tools

## 🏗️ **Architecture**

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Web Browser   │────│   Node.js App   │────│   PostgreSQL    │
│                 │    │                 │    │                 │
│ - HTML/CSS/JS   │    │ - Express.js    │    │ - Health Checks │
│ - Auto-refresh  │    │ - PostgreSQL    │    │ - Data Storage  │
│ - Interactive   │    │ - Health APIs   │    │ - Connection    │
│   Testing       │    │ - Monitoring    │    │   Pool          │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 🚀 **Quick Start**

### **1. Build the Application**
```bash
# Build and push Docker image
./scripts/build-and-push.sh

# Or build manually
cd app
docker build -t muratozcubukcu/terrahelm-webapp:latest .
```

### **2. Deploy with Current Setup**
The application is already configured in your Helm chart:
```bash
# Apply updated configuration
kubectl apply -f argocd-application.yaml

# Check deployment status
kubectl get pods -n terrahelm
kubectl get svc -n terrahelm
```

### **3. Access the Web Interface**
```bash
# Port forward to access locally
kubectl port-forward svc/terrahelm-app 8080:80 -n terrahelm

# Then open: http://localhost:8080
```

## 📡 **API Endpoints**

### **Frontend Status**
```
GET /api/frontend-status
```
Returns pod information, uptime, memory usage, and environment details.

### **Backend Status**
```
GET /api/backend-status
```
Tests PostgreSQL connectivity and returns database metrics, connection pool status, and recent health checks.

### **System Information**
```
GET /api/system-info
```
Provides Kubernetes pod details, application info, and system metrics.

### **Health Check**
```
GET /health
```
Simple health check endpoint for Kubernetes probes.

### **Database Write Test**
```
POST /api/test-write
Body: { "message": "Test message" }
```
Tests database write operations and returns success/failure status.

## 🔧 **Configuration**

### **Environment Variables**
| Variable | Description | Default |
|----------|-------------|---------|
| `PORT` | Application port | `3000` |
| `NODE_ENV` | Environment | `production` |
| `POSTGRES_HOST` | Database host | `localhost` |
| `POSTGRES_PORT` | Database port | `5432` |
| `POSTGRES_DB` | Database name | `appdb` |
| `POSTGRES_USER` | Database user | `appuser` |
| `POSTGRES_PASSWORD` | Database password | `apppassword` |

### **Kubernetes Environment**
These are automatically injected by the deployment:
- `POD_NAME` - Current pod name
- `POD_NAMESPACE` - Kubernetes namespace
- `POD_IP` - Pod IP address
- `NODE_NAME` - Kubernetes node name
- `SERVICE_ACCOUNT` - Service account name

## 🐳 **Docker Configuration**

### **Dockerfile Features**
- **Multi-stage build** for optimized image size
- **Non-root user** for security
- **Health check** built-in
- **Alpine Linux** for minimal footprint
- **Production optimized** dependencies

### **Health Check**
The container includes a built-in health check that tests the `/health` endpoint every 30 seconds.

## 🔒 **Security Features**

### **Container Security**
- Runs as non-root user (nodejs:1001)
- Minimal Alpine Linux base image
- No unnecessary packages or tools
- Production-only dependencies

### **Application Security**
- Input validation on all endpoints
- SQL injection protection via parameterized queries
- CORS configuration
- Error handling without information disclosure

## 📈 **Performance**

### **Optimizations**
- Connection pooling for PostgreSQL (max 10 connections)
- Auto-refresh with visibility API (pauses when tab not active)
- Efficient SQL queries with limits
- Gzip compression support
- Static file serving optimization

### **Resource Usage**
- **Memory**: ~50-100MB typical usage
- **CPU**: Minimal, event-driven architecture
- **Network**: Low bandwidth usage
- **Storage**: Database only for health checks

## 🧪 **Testing**

### **Local Development**
```bash
cd app
npm install
npm run dev

# With database connection
POSTGRES_HOST=localhost npm run dev
```

### **Database Testing**
The web interface includes interactive testing tools:
1. **Connection Test**: Verify database connectivity
2. **Write Test**: Test database write operations
3. **Health History**: View recent activity logs

## 🔄 **Auto-Refresh**

The web interface automatically refreshes every 30 seconds:
- Pauses when browser tab is hidden
- Resumes when tab becomes visible again
- Manual refresh buttons available
- Real-time status indicators

## 📊 **Monitoring Integration**

### **Kubernetes Probes**
- **Liveness Probe**: `/health` endpoint
- **Readiness Probe**: `/health` endpoint
- **Startup Probe**: Built-in Docker health check

### **Metrics Available**
- Database response times
- Connection pool statistics
- Memory and CPU usage
- Application uptime
- Health check history

## 🚨 **Troubleshooting**

### **Common Issues**

1. **Database Connection Failed**
   ```bash
   kubectl logs deployment/terrahelm-app -n terrahelm
   kubectl describe pod <pod-name> -n terrahelm
   ```

2. **Web Interface Not Loading**
   ```bash
   kubectl port-forward svc/terrahelm-app 8080:80 -n terrahelm
   # Check if port 8080 is accessible
   ```

3. **Health Check Failing**
   ```bash
   kubectl exec -it <pod-name> -n terrahelm -- wget -qO- http://localhost:3000/health
   ```

### **Debug Commands**
```bash
# Check pod status
kubectl get pods -n terrahelm -o wide

# View logs
kubectl logs -f deployment/terrahelm-app -n terrahelm

# Test database connectivity
kubectl exec -it <postgresql-pod> -n terrahelm -- psql -U appuser -d appdb

# Check service endpoints
kubectl get endpoints -n terrahelm
```

## 🎯 **Future Enhancements**

- [ ] Prometheus metrics export
- [ ] Grafana dashboard integration
- [ ] WebSocket real-time updates
- [ ] Database migration tools
- [ ] Custom alert thresholds
- [ ] Multi-database support
- [ ] Advanced performance metrics

## 📚 **Documentation**

- `server.js` - Main application server
- `public/index.html` - Web interface
- `package.json` - Dependencies and scripts
- `Dockerfile` - Container build configuration
- `WEBAPP.md` - This documentation

---

**Built with ❤️ for monitoring and testing your Terrahelm deployment!**