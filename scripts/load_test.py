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
from datetime import datetime, timedelta

import httpx
import jwt


async def worker(
    name: int,
    client: httpx.AsyncClient,
    token: str,
    path: str,
    stop_event: asyncio.Event,
    stats: dict,
) -> None:
    headers = {"Authorization": f"Bearer {token}"} if token else {}
    while not stop_event.is_set():
        start = time.perf_counter()
        try:
            response = await client.get(path, headers=headers, timeout=10.0)
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
        "--env",
        choices=["dev", "prod"],
        help="Shortcut to pre-fill host (and default path=/status).",
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
        "--path",
        default=os.getenv("LOADTEST_PATH", "/tasks"),
        help="API path to target (ex: /status)",
    )
    parser.add_argument(
        "--secret",
        default=os.getenv("LOADTEST_SECRET") or os.getenv("SECRET_KEY", ""),
        help="Secret used to mint a short-lived JWT when --token is omitted",
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

    if args.env:
        presets = {
            "dev": {
                "host": "https://api.dev.example-project.com",
                "path": "/status",
            },
            "prod": {
                "host": "https://api.example-project.com",
                "path": "/status",
            },
        }
        preset = presets[args.env]
        if args.host == parser.get_default("host"):
            args.host = preset["host"]
        if args.path == parser.get_default("path"):
            args.path = preset["path"]

    needs_auth = args.path != "/status"
    token = args.token
    generated_token = False
    if needs_auth and not token:
        if not args.secret:
            raise SystemExit(
                "Provide --token or configure --secret/LOADTEST_SECRET to mint a JWT."
            )
        payload = {
            "sub": "loadtest",
            "iat": int(time.time()),
            "exp": int((datetime.utcnow() + timedelta(hours=1)).timestamp()),
        }
        token = jwt.encode(payload, args.secret, algorithm="HS256")
        generated_token = True
    if not needs_auth:
        token = ""

    stats = {"count": 0, "latency_sum": 0.0, "hits": {}, "lock": asyncio.Lock()}
    stop_event = asyncio.Event()

    async with httpx.AsyncClient(base_url=args.host, timeout=10.0) as client:
        tasks = [
            asyncio.create_task(worker(i, client, token, args.path, stop_event, stats))
            for i in range(args.concurrency)
        ]

        await asyncio.sleep(args.duration)
        stop_event.set()
        await asyncio.gather(*tasks, return_exceptions=True)

    total = stats["count"]
    avg_latency = (stats["latency_sum"] / total) if total else 0
    if generated_token:
        print("Generated JWT on the fly using provided secret.")
    print(f"Total requests: {total}")
    print(f"Average latency: {avg_latency * 1000:.2f} ms")
    print("Status codes:")
    for status, qty in sorted(stats["hits"].items()):
        code = status if status != -1 else "error"
        print(f"  {code}: {qty}")


if __name__ == "__main__":
    asyncio.run(main())
