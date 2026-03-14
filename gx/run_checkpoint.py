"""
Ejecuta el checkpoint RAW y genera el reporte HTML (Data Docs).
Retorna exit code 1 si alguna validación falla — el DAG de Airflow lo detecta.
Ejecutar: python3.10 gx/run_checkpoint.py
"""
import sys
sys.path = [p for p in sys.path if "ecommerce-data-platform" not in p]

from dotenv import load_dotenv
from great_expectations.data_context import DataContext

load_dotenv()

context = DataContext(context_root_dir="gx")

result = context.run_checkpoint(checkpoint_name="raw_validation_checkpoint")
context.build_data_docs()

passed = result["success"]
stats = result.run_results

total = len(stats)
failed = sum(1 for r in stats.values() if not r["validation_result"]["success"])

print(f"\n{'✅ PASS' if passed else '❌ FAIL'} — {total - failed}/{total} suites passed")

if not passed:
    print("\nSuites con fallas:")
    for key, r in stats.items():
        if not r["validation_result"]["success"]:
            suite_name = r["validation_result"]["meta"]["expectation_suite_name"]
            expectations = r["validation_result"]["results"]
            failed_exp = [e for e in expectations if not e["success"]]
            print(f"  - {suite_name}: {len(failed_exp)} expectation(s) fallidas")
    sys.exit(1)
