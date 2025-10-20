// Controllers/HealthController.cs
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Progra3_TPFinal_19B.Data;

namespace Progra3_TPFinal_19B.Controllers
{
    public class HealthController : Controller
    {
        private readonly CallCenterDbContext _db;
        public HealthController(CallCenterDbContext db) => _db = db;

        [HttpGet("/health/db")]
        public async Task<IActionResult> Db()
        {
            try
            {
                var ok = await _db.Database.CanConnectAsync();
                return ok ? Ok("DB OK") : StatusCode(503, "DB DOWN (sin excepción)");
            }
            catch (Exception ex)
            {
                return StatusCode(503, $"DB DOWN: {ex.GetType().Name} - {ex.Message}");
            }
        }

        [HttpGet("/health/db/schema")]
        public async Task<IActionResult> DbSchema()
        {
            try
            {
                var conn = _db.Database.GetDbConnection();
                await conn.OpenAsync();

                using var cmd1 = conn.CreateCommand();
                cmd1.CommandText = "SELECT DB_NAME() AS Db, @@SERVERNAME AS ServerName";
                using var r1 = await cmd1.ExecuteReaderAsync();
                await r1.ReadAsync();
                var db = r1["Db"]?.ToString();
                var server = r1["ServerName"]?.ToString();

                using var cmd2 = conn.CreateCommand();
                cmd2.CommandText = @"
            SELECT o.type_desc AS ObjectType, c.name AS ColumnName
            FROM sys.objects o
            JOIN sys.columns c ON c.object_id = o.object_id
            WHERE o.object_id = OBJECT_ID('dbo.Users')
            ORDER BY c.column_id";
                var cols = new List<string>();
                using (var r2 = await cmd2.ExecuteReaderAsync())
                    while (await r2.ReadAsync())
                        cols.Add($"{r2["ObjectType"]}:{r2["ColumnName"]}");

                return Ok(new
                {
                    DataSource = conn.DataSource,
                    Database = db,
                    Server = server,
                    UsersObjectFound = cols.Count > 0,
                    Columns = cols
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, ex.Message);
            }
        }
    }
}
