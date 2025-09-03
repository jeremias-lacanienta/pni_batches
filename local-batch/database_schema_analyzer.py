#!/usr/bin/env python3
"""
PostgreSQL Database Schema Analyzer
Generates a comprehensive analysis of the database schema including:
- Table structures and relationships
- Schema analysis and potential issues
- Data quality assessment
- Recommendations for improvements
"""

import os
import json
import psycopg2
from psycopg2.extras import RealDictCursor
import configparser
from tabulate import tabulate
from collections import defaultdict
import datetime

class DatabaseSchemaAnalyzer:
    def __init__(self):
        # Load PostgreSQL credentials from ~/.aws/credentials
        aws_creds_path = os.path.expanduser('~/.aws/credentials')
        profile = 'postgres-creds'
        config = configparser.ConfigParser()
        config.read(aws_creds_path)

        self.pg_config = {
            'host': config.get(profile, 'pg_host'),
            'port': config.get(profile, 'pg_port', fallback='5432'),
            'database': 'prod',  # Using 'prod' as specified by user
            'user': config.get(profile, 'pg_user'),
            'password': config.get(profile, 'pg_password')
        }
        
        self.conn = None
        self.report = []
        
    def connect(self):
        """Connect to PostgreSQL database"""
        try:
            self.conn = psycopg2.connect(**self.pg_config)
            self.add_to_report(f"✅ Connected to PostgreSQL database: {self.pg_config['database']}")
            return True
        except Exception as e:
            self.add_to_report(f"❌ Error connecting to PostgreSQL: {e}")
            return False
    
    def add_to_report(self, content):
        """Add content to the report"""
        self.report.append(content)
        print(content)
    
    def get_schemas(self):
        """Get all schemas in the database"""
        query = """
        SELECT schema_name 
        FROM information_schema.schemata 
        WHERE schema_name NOT IN ('information_schema', 'pg_catalog', 'pg_toast', 'pg_temp_1', 'pg_toast_temp_1')
        ORDER BY schema_name;
        """
        
        with self.conn.cursor() as cursor:
            cursor.execute(query)
            return [row[0] for row in cursor.fetchall()]
    
    def get_tables_info(self, schema_name):
        """Get detailed information about tables in a schema"""
        query = """
        SELECT 
            t.table_name,
            t.table_type,
            pg_size_pretty(pg_total_relation_size(c.oid)) as size,
            pg_stat_get_tuples_inserted(c.oid) as inserts,
            pg_stat_get_tuples_updated(c.oid) as updates,
            pg_stat_get_tuples_deleted(c.oid) as deletes,
            pg_stat_get_live_tuples(c.oid) as live_tuples,
            pg_stat_get_dead_tuples(c.oid) as dead_tuples,
            obj_description(c.oid) as table_comment
        FROM information_schema.tables t
        LEFT JOIN pg_class c ON c.relname = t.table_name
        LEFT JOIN pg_namespace n ON n.oid = c.relnamespace
        WHERE t.table_schema = %s 
        AND t.table_type = 'BASE TABLE'
        AND n.nspname = %s
        ORDER BY t.table_name;
        """
        
        with self.conn.cursor(cursor_factory=RealDictCursor) as cursor:
            cursor.execute(query, (schema_name, schema_name))
            return cursor.fetchall()
    
    def get_columns_info(self, schema_name, table_name):
        """Get detailed column information for a table"""
        query = """
        SELECT 
            c.column_name,
            c.data_type,
            c.character_maximum_length,
            c.numeric_precision,
            c.numeric_scale,
            c.is_nullable,
            c.column_default,
            c.ordinal_position,
            col_description(pgc.oid, c.ordinal_position) as column_comment,
            CASE WHEN pk.column_name IS NOT NULL THEN 'YES' ELSE 'NO' END as is_primary_key,
            CASE WHEN fk.column_name IS NOT NULL THEN 'YES' ELSE 'NO' END as is_foreign_key
        FROM information_schema.columns c
        LEFT JOIN pg_class pgc ON pgc.relname = c.table_name
        LEFT JOIN pg_namespace pgn ON pgn.oid = pgc.relnamespace AND pgn.nspname = c.table_schema
        LEFT JOIN (
            SELECT kcu.column_name, kcu.table_name, kcu.table_schema
            FROM information_schema.table_constraints tc
            JOIN information_schema.key_column_usage kcu 
                ON tc.constraint_name = kcu.constraint_name
            WHERE tc.constraint_type = 'PRIMARY KEY'
        ) pk ON pk.column_name = c.column_name 
            AND pk.table_name = c.table_name 
            AND pk.table_schema = c.table_schema
        LEFT JOIN (
            SELECT kcu.column_name, kcu.table_name, kcu.table_schema
            FROM information_schema.table_constraints tc
            JOIN information_schema.key_column_usage kcu 
                ON tc.constraint_name = kcu.constraint_name
            WHERE tc.constraint_type = 'FOREIGN KEY'
        ) fk ON fk.column_name = c.column_name 
            AND fk.table_name = c.table_name 
            AND fk.table_schema = c.table_schema
        WHERE c.table_schema = %s AND c.table_name = %s
        ORDER BY c.ordinal_position;
        """
        
        with self.conn.cursor(cursor_factory=RealDictCursor) as cursor:
            cursor.execute(query, (schema_name, table_name))
            return cursor.fetchall()
    
    def get_foreign_keys(self, schema_name):
        """Get all foreign key relationships"""
        query = """
        SELECT
            tc.constraint_name,
            tc.table_schema,
            tc.table_name,
            kcu.column_name,
            ccu.table_schema AS foreign_table_schema,
            ccu.table_name AS foreign_table_name,
            ccu.column_name AS foreign_column_name,
            COALESCE(rc.update_rule, 'NO ACTION') as update_rule,
            COALESCE(rc.delete_rule, 'NO ACTION') as delete_rule
        FROM information_schema.table_constraints AS tc
        JOIN information_schema.key_column_usage AS kcu
            ON tc.constraint_name = kcu.constraint_name
            AND tc.table_schema = kcu.table_schema
        JOIN information_schema.constraint_column_usage AS ccu
            ON ccu.constraint_name = tc.constraint_name
        LEFT JOIN information_schema.referential_constraints AS rc
            ON tc.constraint_name = rc.constraint_name
            AND tc.table_schema = rc.constraint_schema
        WHERE tc.constraint_type = 'FOREIGN KEY'
        AND tc.table_schema = %s
        ORDER BY tc.table_name, tc.constraint_name;
        """
        
        with self.conn.cursor(cursor_factory=RealDictCursor) as cursor:
            cursor.execute(query, (schema_name,))
            return cursor.fetchall()
    
    def get_indexes(self, schema_name):
        """Get all indexes for tables in the schema"""
        query = """
        SELECT
            schemaname,
            tablename,
            indexname,
            indexdef,
            COALESCE(pg_size_pretty(pg_relation_size(quote_ident(schemaname)||'.'||quote_ident(indexname))), 'N/A') as index_size
        FROM pg_indexes
        WHERE schemaname = %s
        ORDER BY tablename, indexname;
        """
        
        with self.conn.cursor(cursor_factory=RealDictCursor) as cursor:
            cursor.execute(query, (schema_name,))
            return cursor.fetchall()
    
    def get_constraints(self, schema_name):
        """Get all constraints"""
        query = """
        SELECT
            tc.constraint_name,
            tc.table_name,
            tc.constraint_type,
            kcu.column_name,
            cc.check_clause
        FROM information_schema.table_constraints tc
        LEFT JOIN information_schema.key_column_usage kcu
            ON tc.constraint_name = kcu.constraint_name
            AND tc.table_schema = kcu.table_schema
        LEFT JOIN information_schema.check_constraints cc
            ON tc.constraint_name = cc.constraint_name
        WHERE tc.table_schema = %s
        ORDER BY tc.table_name, tc.constraint_type, tc.constraint_name;
        """
        
        with self.conn.cursor(cursor_factory=RealDictCursor) as cursor:
            cursor.execute(query, (schema_name,))
            return cursor.fetchall()
    
    def analyze_data_quality(self, schema_name, table_name):
        """Analyze data quality for a table"""
        issues = []
        
        with self.conn.cursor(cursor_factory=RealDictCursor) as cursor:
            # Get total row count
            cursor.execute(f'SELECT COUNT(*) as total FROM "{schema_name}"."{table_name}"')
            total_rows = cursor.fetchone()['total']
            
            if total_rows == 0:
                issues.append("⚠️ Table is empty")
                return issues, total_rows
            
            # Get columns
            columns = self.get_columns_info(schema_name, table_name)
            
            for col in columns:
                col_name = col['column_name']
                data_type = col['data_type']
                
                # Check for NULL values in NOT NULL columns
                if col['is_nullable'] == 'NO':
                    cursor.execute(f'SELECT COUNT(*) as null_count FROM "{schema_name}"."{table_name}" WHERE "{col_name}" IS NULL')
                    null_count = cursor.fetchone()['null_count']
                    if null_count > 0:
                        issues.append(f"❌ Column '{col_name}' (NOT NULL) has {null_count} NULL values")
                
                # Check for empty strings in text columns
                if data_type in ['text', 'varchar', 'character varying']:
                    cursor.execute(f'SELECT COUNT(*) as empty_count FROM "{schema_name}"."{table_name}" WHERE "{col_name}" = \'\'')
                    empty_count = cursor.fetchone()['empty_count']
                    if empty_count > 0:
                        issues.append(f"⚠️ Column '{col_name}' has {empty_count} empty strings")
                
                # Check for duplicate values in primary key columns
                if col['is_primary_key'] == 'YES':
                    cursor.execute(f'SELECT COUNT(*) as total, COUNT(DISTINCT "{col_name}") as distinct FROM "{schema_name}"."{table_name}"')
                    result = cursor.fetchone()
                    if result['total'] != result['distinct']:
                        issues.append(f"❌ Primary key column '{col_name}' has duplicate values")
        
        return issues, total_rows
    
    def generate_markdown_report(self):
        """Generate comprehensive markdown report"""
        self.add_to_report(f"# PostgreSQL Database Schema Analysis Report")
        self.add_to_report(f"**Database:** {self.pg_config['database']}")
        self.add_to_report(f"**Generated:** {datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        self.add_to_report("")
        
        # Get all schemas
        schemas = self.get_schemas()
        self.add_to_report(f"## Database Overview")
        self.add_to_report(f"**Total Schemas:** {len(schemas)}")
        self.add_to_report(f"**Schemas:** {', '.join(schemas)}")
        self.add_to_report("")
        
        # Analyze each schema
        for schema_name in schemas:
            self.add_to_report(f"## Schema: `{schema_name}`")
            self.add_to_report("")
            
            # Get tables
            tables = self.get_tables_info(schema_name)
            
            if not tables:
                self.add_to_report("*No tables found in this schema.*")
                self.add_to_report("")
                continue
            
            self.add_to_report(f"### Tables Overview")
            
            # Create tables summary
            table_data = []
            total_size = 0
            total_rows = 0
            
            for table in tables:
                table_name = table['table_name']
                size = table['size'] or '0 bytes'
                live_tuples = table['live_tuples'] or 0
                
                table_data.append([
                    table_name,
                    table['table_type'],
                    size,
                    f"{live_tuples:,}",
                    table['table_comment'] or 'No description'
                ])
                
                total_rows += live_tuples
            
            self.add_to_report(tabulate(
                table_data,
                headers=['Table Name', 'Type', 'Size', 'Rows', 'Description'],
                tablefmt='pipe'
            ))
            self.add_to_report("")
            self.add_to_report(f"**Total Tables:** {len(tables)}")
            self.add_to_report(f"**Total Rows:** {total_rows:,}")
            self.add_to_report("")
            
            # Detailed table analysis
            for table in tables:
                table_name = table['table_name']
                self.add_to_report(f"### Table: `{table_name}`")
                
                if table['table_comment']:
                    self.add_to_report(f"**Description:** {table['table_comment']}")
                
                # Table statistics
                stats_data = [
                    ['Size', table['size'] or '0 bytes'],
                    ['Live Tuples', f"{table['live_tuples'] or 0:,}"],
                    ['Dead Tuples', f"{table['dead_tuples'] or 0:,}"],
                    ['Inserts', f"{table['inserts'] or 0:,}"],
                    ['Updates', f"{table['updates'] or 0:,}"],
                    ['Deletes', f"{table['deletes'] or 0:,}"]
                ]
                
                self.add_to_report(tabulate(
                    stats_data,
                    headers=['Metric', 'Value'],
                    tablefmt='pipe'
                ))
                self.add_to_report("")
                
                # Column information
                columns = self.get_columns_info(schema_name, table_name)
                
                self.add_to_report(f"#### Columns")
                
                column_data = []
                for col in columns:
                    data_type_display = col['data_type']
                    if col['character_maximum_length']:
                        data_type_display += f"({col['character_maximum_length']})"
                    elif col['numeric_precision']:
                        if col['numeric_scale']:
                            data_type_display += f"({col['numeric_precision']},{col['numeric_scale']})"
                        else:
                            data_type_display += f"({col['numeric_precision']})"
                    
                    flags = []
                    if col['is_primary_key'] == 'YES':
                        flags.append('PK')
                    if col['is_foreign_key'] == 'YES':
                        flags.append('FK')
                    if col['is_nullable'] == 'NO':
                        flags.append('NOT NULL')
                    
                    column_data.append([
                        col['column_name'],
                        data_type_display,
                        ' | '.join(flags) if flags else '-',
                        col['column_default'] or '-',
                        col['column_comment'] or '-'
                    ])
                
                self.add_to_report(tabulate(
                    column_data,
                    headers=['Column', 'Type', 'Constraints', 'Default', 'Description'],
                    tablefmt='pipe'
                ))
                self.add_to_report("")
                
                # Data quality analysis
                self.add_to_report(f"#### Data Quality Analysis")
                issues, row_count = self.analyze_data_quality(schema_name, table_name)
                
                if not issues:
                    self.add_to_report("✅ No data quality issues detected")
                else:
                    for issue in issues:
                        self.add_to_report(issue)
                
                self.add_to_report("")
            
            # Foreign Key Relationships
            foreign_keys = self.get_foreign_keys(schema_name)
            
            if foreign_keys:
                self.add_to_report(f"### Foreign Key Relationships")
                
                fk_data = []
                for fk in foreign_keys:
                    fk_data.append([
                        fk['table_name'],
                        fk['column_name'],
                        f"{fk['foreign_table_name']}.{fk['foreign_column_name']}",
                        fk['delete_rule'],
                        fk['update_rule']
                    ])
                
                self.add_to_report(tabulate(
                    fk_data,
                    headers=['Table', 'Column', 'References', 'On Delete', 'On Update'],
                    tablefmt='pipe'
                ))
                self.add_to_report("")
            
            # Indexes
            indexes = self.get_indexes(schema_name)
            
            if indexes:
                self.add_to_report(f"### Indexes")
                
                index_data = []
                for idx in indexes:
                    index_data.append([
                        idx['tablename'],
                        idx['indexname'],
                        idx['indexdef'],
                        idx['index_size']
                    ])
                
                self.add_to_report(tabulate(
                    index_data,
                    headers=['Table', 'Index Name', 'Definition', 'Size'],
                    tablefmt='pipe'
                ))
                self.add_to_report("")
            
            # Constraints
            constraints = self.get_constraints(schema_name)
            
            if constraints:
                self.add_to_report(f"### Constraints")
                
                constraint_data = []
                for constraint in constraints:
                    constraint_data.append([
                        constraint['table_name'],
                        constraint['constraint_name'],
                        constraint['constraint_type'],
                        constraint['column_name'] or '-',
                        constraint['check_clause'] or '-'
                    ])
                
                self.add_to_report(tabulate(
                    constraint_data,
                    headers=['Table', 'Constraint', 'Type', 'Column', 'Check Clause'],
                    tablefmt='pipe'
                ))
                self.add_to_report("")
        
        # Schema Analysis and Recommendations
        self.add_to_report("## Schema Analysis & Recommendations")
        self.add_to_report("")
        
        # Analyze potential issues
        issues_found = []
        recommendations = []
        
        for schema_name in schemas:
            tables = self.get_tables_info(schema_name)
            foreign_keys = self.get_foreign_keys(schema_name)
            
            # Check for tables without primary keys
            for table in tables:
                table_name = table['table_name']
                columns = self.get_columns_info(schema_name, table_name)
                has_pk = any(col['is_primary_key'] == 'YES' for col in columns)
                
                if not has_pk:
                    issues_found.append(f"❌ Table `{schema_name}.{table_name}` has no primary key")
                    recommendations.append(f"Add a primary key to `{schema_name}.{table_name}` for better performance and data integrity")
                
                # Check for very large tables without partitioning
                if table['live_tuples'] and table['live_tuples'] > 1000000:
                    recommendations.append(f"Consider partitioning large table `{schema_name}.{table_name}` ({table['live_tuples']:,} rows)")
                
                # Check for tables with high dead tuple ratio
                if table['dead_tuples'] and table['live_tuples']:
                    dead_ratio = table['dead_tuples'] / (table['live_tuples'] + table['dead_tuples'])
                    if dead_ratio > 0.2:
                        issues_found.append(f"⚠️ Table `{schema_name}.{table_name}` has high dead tuple ratio ({dead_ratio:.1%})")
                        recommendations.append(f"Consider running VACUUM on `{schema_name}.{table_name}` to clean up dead tuples")
            
            # Check for orphaned foreign key references
            for fk in foreign_keys:
                # This would require more complex queries to detect actual orphaned records
                if fk['delete_rule'] == 'NO ACTION' and fk['update_rule'] == 'NO ACTION':
                    recommendations.append(f"Review foreign key `{fk['constraint_name']}` cascade rules for better data integrity")
        
        # General schema issues
        if len(schemas) == 1 and schemas[0] == 'public':
            recommendations.append("Consider organizing tables into logical schemas instead of using only the 'public' schema")
        
        # Display issues and recommendations
        if issues_found:
            self.add_to_report("### Critical Issues Found")
            for issue in issues_found:
                self.add_to_report(issue)
            self.add_to_report("")
        
        if recommendations:
            self.add_to_report("### Recommendations")
            for i, rec in enumerate(recommendations, 1):
                self.add_to_report(f"{i}. {rec}")
            self.add_to_report("")
        
        # Security considerations
        self.add_to_report("### Security Considerations")
        self.add_to_report("1. Ensure sensitive data columns are properly encrypted")
        self.add_to_report("2. Implement row-level security (RLS) where appropriate")
        self.add_to_report("3. Regular security audits of user permissions")
        self.add_to_report("4. Consider using database roles instead of individual user permissions")
        self.add_to_report("")
        
        # Performance considerations
        self.add_to_report("### Performance Considerations")
        self.add_to_report("1. Monitor and analyze slow queries regularly")
        self.add_to_report("2. Ensure proper indexing on frequently queried columns")
        self.add_to_report("3. Consider implementing connection pooling")
        self.add_to_report("4. Regular VACUUM and ANALYZE operations")
        self.add_to_report("5. Monitor database size and plan for scaling")
        self.add_to_report("")
    
    def save_report(self, filename):
        """Save the report to a file"""
        with open(filename, 'w') as f:
            f.write('\n'.join(self.report))
        
        print(f"\n📄 Report saved to: {filename}")
    
    def run_analysis(self):
        """Run the complete database analysis"""
        if not self.connect():
            return False
        
        try:
            self.generate_markdown_report()
            return True
        except Exception as e:
            self.add_to_report(f"❌ Error during analysis: {e}")
            return False
        finally:
            if self.conn:
                self.conn.close()

def main():
    analyzer = DatabaseSchemaAnalyzer()
    
    print("🔍 Starting PostgreSQL Database Schema Analysis...")
    print(f"Database: {analyzer.pg_config['database']}")
    print(f"Host: {analyzer.pg_config['host']}")
    print("=" * 60)
    
    if analyzer.run_analysis():
        # Save report to file
        timestamp = datetime.datetime.now().strftime('%Y%m%d_%H%M%S')
        filename = f"database_schema_analysis_{timestamp}.md"
        analyzer.save_report(filename)
        
        print("\n✅ Analysis completed successfully!")
        print(f"📊 Full report saved to: {filename}")
    else:
        print("\n❌ Analysis failed!")

if __name__ == "__main__":
    main()
