#!/usr/bin/env python3
"""
Quick load-test helper for the Tasks API.

Usage:
    python scripts/load_test.py --host https://api.dev.example-project.com \
        --token <JWT> --duration 60 --concurrency 20
"""

import argparse
import asyncio
import os
import time

import httpx


async def worker(
    name: int,
    client: httpx.AsyncClient,
    token: str,
    stop_event: asyncio.Event,
    stats: dict,
) -> None:
    headers = {"Authorization": f"Bearer {token}"}
    while not stop_event.is_set():
        start = time.perf_counter()
        try:
            response = await client.get("/tasks", headers=headers, timeout=10.0)
            latency = time.perf_counter() - start
            status = response.status_code
        except Exception:
            latency = time.perf_counter() - start
            status = -1
        async with stats["lock"]:
            stats["count"] += 1
            stats["latency_sum"] += latency
            stats["hits"][status] = stats["hits"].get(status, 0) + 1


async def main() -> None:
    parser = argparse.ArgumentParser(
        description="Simple async load tester for the Tasks API"
    )
    parser.add_argument(
        "--host",
        default=os.getenv("LOADTEST_HOST", "http://localhost:8080"),
        help="Base URL of the API",
    )
    parser.add_argument(
        "--token",
        default=os.getenv("LOADTEST_TOKEN", ""),
        help="JWT token for Authorization header",
    )
    parser.add_argument(
        "--concurrency",
        type=int,
        default=int(os.getenv("LOADTEST_CONCURRENCY", "10")),
        help="Concurrent clients",
    )
    parser.add_argument(
        "--duration",
        type=int,
        default=int(os.getenv("LOADTEST_DURATION", "60")),
        help="Duration in seconds",
    )
    args = parser.parse_args()

    if not args.token:
        raise SystemExit(
            "Provide a JWT token via --token or LOADTEST_TOKEN environment variable."
        )

    stats = {"count": 0, "latency_sum": 0.0, "hits": {}, "lock": asyncio.Lock()}
    stop_event = asyncio.Event()

    async with httpx.AsyncClient(base_url=args.host, timeout=10.0) as client:
        tasks = [
            asyncio.create_task(worker(i, client, args.token, stop_event, stats))
            for i in range(args.concurrency)
        ]

        await asyncio.sleep(args.duration)
        stop_event.set()
        await asyncio.gather(*tasks, return_exceptions=True)

    total = stats["count"]
    avg_latency = (stats["latency_sum"] / total) if total else 0
    print(f"Total requests: {total}")
    print(f"Average latency: {avg_latency * 1000:.2f} ms")
    print("Status codes:")
    for status, qty in sorted(stats["hits"].items()):
        code = status if status != -1 else "error"
        print(f"  {code}: {qty}")


if __name__ == "__main__":
    asyncio.run(main())
