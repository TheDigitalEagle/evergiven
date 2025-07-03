# EverGiven - Order Management API

A lightweight Go-based REST API for managing orders from China, optimized for Raspberry Pi 5 deployment and custom GPT integration.

## Features

- **Dual Database Support**: SQLite (lightweight) or PostgreSQL (production)
- **Dual Currency**: Track costs in both CNY and USD
- **RESTful API**: Full CRUD operations for orders
- **Health Monitoring**: Built-in health check endpoint
- **CORS Support**: Ready for web and GPT integration
- **Resource Optimized**: Designed for Raspberry Pi 5

## Quick Start

### Option 1: SQLite (Recommended for Pi)

```bash
# Clone and build
git clone <your-repo>
cd evergiven

# Run with SQLite (lightweight)
docker-compose up -d api
```

### Option 2: PostgreSQL

```bash
# Run with PostgreSQL
docker-compose up -d
```

## API Endpoints

### Health Check
```
GET /health
```
Returns service status and database connectivity.

### Orders
```
GET    /orders          # List all orders
POST   /orders          # Create new order
PUT    /orders/{id}     # Update order
DELETE /orders/{id}     # Delete order
```

## Order Schema

```json
{
  "orderId": 1,
  "dateOfOrder": "2024-01-15T10:30:00Z",
  "trackingNumber": "TRK123456789",
  "shortDescriptOfItem": "Wireless Earbuds",
  "orderQuantity": 10,
  "costPerItemCNY": "299.99",
  "totalPerItemCNY": "2999.90",
  "costPerItemUSD": "42.50",
  "totalPerItemUSD": "425.00"
}
```

## Raspberry Pi 5 Deployment

### Prerequisites
- Raspberry Pi 5 with 4GB+ RAM
- Docker and Docker Compose installed
- Network access for GPT integration

### Installation

1. **Install Docker on Pi 5:**
```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
```

2. **Install Docker Compose:**
```bash
sudo apt-get update
sudo apt-get install docker-compose-plugin
```

3. **Deploy the application:**
```bash
git clone <your-repo>
cd evergiven
docker-compose up -d api
```

### Resource Monitoring

The application includes resource limits optimized for Pi 5:
- API Service: 512MB RAM, 0.5 CPU cores
- Database: 256MB RAM, 0.25 CPU cores

Monitor with:
```bash
docker stats
```

## Custom GPT Integration

### Configuration for ChatGPT Custom GPT

1. **Set up your Pi's IP address:**
   - Find your Pi's IP: `hostname -I`
   - Ensure port 8080 is accessible

2. **Configure your Custom GPT:**
   - Add your Pi's URL: `http://YOUR_PI_IP:8080`
   - Use these endpoints in your GPT configuration

3. **Example GPT Actions:**
```yaml
# List all orders
GET {{base_url}}/orders

# Create new order
POST {{base_url}}/orders
Content-Type: application/json

{
  "dateOfOrder": "2024-01-15T10:30:00Z",
  "trackingNumber": "TRK123456789",
  "shortDescriptOfItem": "Wireless Earbuds",
  "orderQuantity": 10,
  "costPerItemCNY": "299.99",
  "totalPerItemCNY": "2999.90",
  "costPerItemUSD": "42.50",
  "totalPerItemUSD": "425.00"
}
```

### Security Considerations

For production GPT integration:

1. **Add Authentication:**
```bash
# Set environment variable
export API_KEY=your-secret-key
```

2. **Restrict CORS origins:**
   - Update CORS configuration in `main.go`
   - Replace `"*"` with specific domains

3. **Use HTTPS:**
   - Set up reverse proxy with nginx
   - Configure SSL certificates

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `DATABASE_URL` | `sqlite:///app/evergiven.db` | Database connection string |
| `PORT` | `8080` | API server port |
| `API_KEY` | (none) | Optional API key for authentication |

## Database Options

### SQLite (Default - Lightweight)
```bash
DATABASE_URL=sqlite:///app/evergiven.db
```
- **Pros**: No external dependencies, fast startup
- **Cons**: Limited concurrent access
- **Best for**: Single-user, development, Pi deployment

### PostgreSQL (Production)
```bash
DATABASE_URL=postgres://user:pass@localhost:5432/dbname
```
- **Pros**: ACID compliance, concurrent access
- **Cons**: Higher resource usage
- **Best for**: Multi-user, production environments

## Monitoring and Logs

### View logs:
```bash
docker-compose logs -f api
```

### Health check:
```bash
curl http://localhost:8080/health
```

### Database backup (SQLite):
```bash
docker cp evergiven-api-1:/app/evergiven.db ./backup.db
```

## Troubleshooting

### Common Issues

1. **Port already in use:**
```bash
sudo lsof -i :8080
sudo kill -9 <PID>
```

2. **Database connection failed:**
```bash
docker-compose logs db
docker-compose restart api
```

3. **Permission denied:**
```bash
sudo chown -R $USER:$USER ./data
```

### Performance Tuning

For better Pi 5 performance:

1. **Enable swap:**
```bash
sudo dphys-swapfile swapoff
sudo nano /etc/dphys-swapfile
# Set CONF_SWAPSIZE=2048
sudo dphys-swapfile setup
sudo dphys-swapfile swapon
```

2. **Overclock (optional):**
```bash
sudo raspi-config
# Performance Options > Overclock
```

## Development

### Local Development
```bash
go mod tidy
go run main.go
```

### Build for Pi
```bash
GOOS=linux GOARCH=arm64 go build -o evergiven
```

## License

MIT License - see LICENSE file for details. 