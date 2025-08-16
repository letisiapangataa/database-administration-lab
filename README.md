# Database Administration Lab

A practical lab environment focused on SQL Server and MySQL database administration, security hardening, backup automation, and performance optimization. Built to simulate real-world database management scenarios for secure and reliable operations.

---

## Project Overview

This project demonstrates key practices in database administration, particularly for environments requiring high availability, security, and performance. It includes scripted configurations, security enhancements, backup and restore automation, and hands-on performance tuning techniques.

---

## Key Highlights

- **Database Security Hardening**: Role-based access, user auditing, and privilege restrictions.
- **Automated Backup Solutions**: Full, differential, and incremental backups using native tools and scripts.
- **Query Optimization Techniques**: Indexing, execution plan analysis, and stored procedure tuning.
- **Disaster Recovery Testing**: Simulated outage scenarios with documented recovery procedures.

---

## Technologies Used

| Technology     | Purpose                                  |
|----------------|-------------------------------------------|
| SQL Server      | Enterprise-grade RDBMS for hands-on tasks |
| MySQL           | Lightweight and open-source DB testing    |
| T-SQL / SQL     | Querying, scripting, and performance tuning|
| Performance Tuning Tools | Execution plans, indexing, EXPLAIN |

---

## Repository Structure

| Folder         | Contents                                              |
|----------------|-------------------------------------------------------|
| `/sql-scripts/`| SQL scripts for security, backup, optimization, DR    |
| `/docs/`       | Guides and test reports for tuning and recovery       |
| `/configs/`    | Custom config files for SQL Server and MySQL          |

---

## Sample Use Cases

- Configure user roles with least privilege access  
- Automate nightly backups using scheduled SQL Agent Jobs or cron  
- Analyze long-running queries using `EXPLAIN` and tuning indexes  
- Simulate data loss and perform point-in-time recovery testing  

---

## Best Practices Demonstrated

- Security-first database setup  
- Data retention policy compliance  
- Reliable recovery under failure conditions  
- Performance benchmarking of SQL workloads  

---

## License

MIT License

---

## References

- [Microsoft SQL Server Docs](https://learn.microsoft.com/sql/)
- [MySQL Documentation](https://dev.mysql.com/doc/)
- [Brent Ozar SQL Performance Guide](https://www.brentozar.com/)

---

## Disclaimer

This project was developed using a combination of publicly available learning resources, reference books, open source projects, and artificial intelligence tools. All efforts have been made to attribute and comply with relevant licenses. Contributions and insights from the broader open source and educational communities are gratefully acknowledged. This software is provided as-is, without warranty of any kind, express or implied. The author assumes no responsibility for any loss, damage, or disruption caused by the use of this code. It is intended for educational and experimental purposes only and may not be suitable for production environments.



