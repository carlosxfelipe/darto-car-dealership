#!/bin/bash
echo "======================================"
echo "--- Benchmark: Darto (Local) ---"
echo "======================================"

kill_port() {
  local port=$1
  if [[ "$OSTYPE" == "darwin"* ]]; then
    lsof -ti tcp:${port} | xargs kill -9 2>/dev/null || true
  else
    fuser -k ${port}/tcp 2>/dev/null || true
  fi
}

kill_port 3000

echo "Compilando Darto..."
dart compile exe bin/server.dart -o server

echo "Iniciando servidor Darto..."
./server > /dev/null 2>&1 &
PID=$!

echo "Aguardando inicialização do servidor (5s)..."
sleep 5

echo "Iniciando teste de carga com autocannon (10 segundos, 100 conexões)..."
npx -y autocannon -c 100 -d 10 http://localhost:3000/cars

echo "Limpando processos..."
kill -9 $PID 2>/dev/null || true
kill_port 3000
rm -f server
echo "Benchmark Local Concluído!"
