//===----------------------------------------------------------------------===//
//
// This source file is part of the Hummingbird server framework project
//
// Copyright (c) 2024 the Hummingbird authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See hummingbird/CONTRIBUTORS.txt for the list of Hummingbird authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import Logging
import PostgresMigrations
import PostgresNIO

struct CreateJobsMigration: DatabaseMigration {
    func apply(connection: PostgresConnection, logger: Logger) async throws {
        try await connection.query(
            """
            CREATE TABLE IF NOT EXISTS swift_jobs (
                id UUID NOT NULL PRIMARY KEY,
                job_name VARCHAR(255) NOT NULL,
                payload BYTEA NOT NULL,
                status SMALLINT NOT NULL,
                did_pause BOOLEAN NOT NULL DEFAULT FALSE,
                priority INTEGER NOT NULL DEFAULT 10,
                updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
                created_at TIMESTAMPTZ NOT NULL DEFAULT NOW() NOT NULL,
                delayed_until TIMESTAMPTZ,
                debounce_key TEXT NOT NULL UNIQUE
            );
            """,
            logger: logger
        )
        try await connection.query(
            """
            CREATE INDEX IF NOT EXISTS _hb_job_status_idx
            ON swift_jobs(status)
            """,
            logger: logger
        )
        try await connection.query(
            """
            CREATE INDEX IF NOT EXISTS _hb_job_filter_idx
            ON swift_jobs(priority, created_at, delayed_until)
            """,
            logger: logger
        )
    }

    func revert(connection: PostgresConnection, logger: Logger) async throws {
        try await connection.query(
            "DROP TABLE swift_jobs",
            logger: logger
        )
    }

    var name: String { "_Create_Jobs_Table_" }
    var group: DatabaseMigrationGroup { .jobQueue }
}

extension DatabaseMigrationGroup {
    /// JobQueue migration group
    public static var jobQueue: Self { .init("swift_jobs") }
}
