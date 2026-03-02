# -----------------------------
# Dorchester EMS Data Mart
# ETL Makefile
# -----------------------------

# Defaults (override with env vars if needed)
DB_HOST ?= localhost
DB_PORT ?= 5432
DB_NAME ?= ems_mart
DB_USER ?= zach
DB_SSLMODE ?= prefer

ETL_RUNNER = etl/00_run_all_upserts.sql
LOG_DIR = logs

.PHONY: help etl etl-quiet etl-timed check clean-logs

help:
	@echo ""
	@echo "Available targets:"
	@echo "  make etl        -> Run full ETL with logging"
	@echo "  make etl-quiet  -> Run ETL with minimal console noise"
	@echo "  make etl-timed  -> Run ETL with statement timing"
	@echo "  make check      -> Verify DB connectivity"
	@echo "  make clean-logs -> Remove old ETL logs"
	@echo ""

$(LOG_DIR):
	mkdir -p $(LOG_DIR)

check:
	psql "host=$(DB_HOST) port=$(DB_PORT) user=$(DB_USER) dbname=$(DB_NAME) sslmode=$(DB_SSLMODE)" \
		-c "SELECT current_database(), current_user;"

etl: $(LOG_DIR)
	@ts=$$(date +%Y%m%d_%H%M%S); \
	log="$(LOG_DIR)/etl_run_$${ts}.log"; \
	echo "Running ETL -> $(DB_USER)@$(DB_HOST):$(DB_PORT)/$(DB_NAME)"; \
	echo "Logging to $$log"; \
	psql \
	  "host=$(DB_HOST) port=$(DB_PORT) user=$(DB_USER) dbname=$(DB_NAME) sslmode=$(DB_SSLMODE)" \
	  -v ON_ERROR_STOP=1 \
	  -f $(ETL_RUNNER) \
	  2>&1 | tee $$log

etl-quiet: $(LOG_DIR)
	@ts=$$(date +%Y%m%d_%H%M%S); \
	log="$(LOG_DIR)/etl_run_$${ts}.log"; \
	psql -X -q \
	  "host=$(DB_HOST) port=$(DB_PORT) user=$(DB_USER) dbname=$(DB_NAME) sslmode=$(DB_SSLMODE)" \
	  -v ON_ERROR_STOP=1 \
	  -f $(ETL_RUNNER) \
	  2>&1 | tee $$log

etl-timed: $(LOG_DIR)
	@ts=$$(date +%Y%m%d_%H%M%S); \
	log="$(LOG_DIR)/etl_run_$${ts}.log"; \
	psql \
	  "host=$(DB_HOST) port=$(DB_PORT) user=$(DB_USER) dbname=$(DB_NAME) sslmode=$(DB_SSLMODE)" \
	  -v ON_ERROR_STOP=1 \
	  -v ETL_TIMING=on \
	  -f $(ETL_RUNNER) \
	  2>&1 | tee $$log

clean-logs:
	rm -f $(LOG_DIR)/etl_run_*.log

