#!/bin/bash

set -e # stop on first failure

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}"
echo "### Starting script..."

echo -e "${YELLOW}[1/6] Check dependencies...${NC}"

if ! command -v docker &> /dev/null; then
    echo -e "${RED}|- Docker not found.${NC}"
    echo -e "${YELLOW}|--- Install it via: https://docs.docker.com/get-docker/${NC}"
    exit 1
fi

if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo -e "${RED}|-  Docker Compose not found.${NC}"
    echo -e "${YELLOW}|--- Install it via: https://docs.docker.com/compose/install/${NC}"
    exit 1
fi

echo -e "${GREEN}|- Docker and Docker Compose found${NC}"

echo -e "${YELLOW}[2/6] Setting environment variables...${NC}"

if [ ! -f duo-f1-backend/.env ]; then
    echo -e "${BLUE}|- Creating duo-f1-backend/.env...${NC}"
    cp duo-f1-backend/.env.example duo-f1-backend/.env
    
    rm duo-f1-backend/.env.bak 2>/dev/null || true
    
    echo -e "${GREEN}|- duo-f1-backend/.env created${NC}"
else
    echo -e "${GREEN}|- duo-f1-backend/.env already exists${NC}"
fi

echo -e "${YELLOW}[3/6] Stopping existing containers...${NC}"
docker compose down 2>/dev/null || true

echo -e "${YELLOW}[4/6] Building Docker images...${NC}"
docker compose build --no-cache

echo -e "${YELLOW}[5/6] Starting containers...${NC}"
docker compose up -d

echo -e "${YELLOW}[6/6] Wait a second, checking something! ${NC}"

echo -e "${BLUE} **** ⏳ Waiting Redis...${NC}"
until docker compose exec -T redis redis-cli ping &> /dev/null; do
    sleep 1
done
echo -e "${GREEN}|- Redis check ✅ ${NC}"

echo -e "${BLUE} **** ⏳ Waiting Backend...${NC}"
until curl -sf http://localhost:8001/api/health &> /dev/null; do
    sleep 2
done
echo -e "${GREEN}|- Backend check ✅ ${NC}"

echo -e "${BLUE} **** ⏳ Waiting Frontend...${NC}"
until curl -sf http://localhost:5173 &> /dev/null; do
    sleep 2
done
echo -e "${GREEN}|- Frontend check ✅ ${NC}"

echo ""
echo -e "${GREEN}"
echo "##### ✅ Setup loaded successfully!"
echo -e "${NC}"
echo ""
echo -e "${BLUE}|- Services available in (dev enviroment):${NC}"
echo -e "   Frontend:  ${GREEN}http://localhost:5173${NC}"
echo -e "   Backend:   ${GREEN}http://localhost:8001${NC}"
echo -e "   Redis:     ${GREEN}localhost:6379${NC}"
echo ""