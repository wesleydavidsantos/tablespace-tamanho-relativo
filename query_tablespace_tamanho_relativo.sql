--
-- Query que apresenta o tamanho Real e Relativo sobre as tablespaces do Oracle
--
-- Query that presents the Real and Relative size of Oracle tablespaces.
--
-- Autor: Wesley David Santos
-- Skype: wesleydavidsantos
-- https://www.linkedin.com/in/wesleydavidsantos
--
-- Link descrevendo o funcionamento ( Link describing how it works )
-- https://www.linkedin.com/pulse/tablespace-de-tamanho-relativo-voc%C3%AA-j%C3%A1-ouviu-falar-david-santos
-- 

select 
	 tablespace_name
	,mb_alloc
	,mb_free_alloc
	,mb_used_alloc
	,pct_free_mb_alloc 
	,pct_used_mb_alloc
	,mb_max
	,( mb_max - mb_used_alloc ) mb_total_free    
	,round((nvl( ( mb_max - mb_used_alloc ) , 0) / mb_max) * 100, 2) pct_total_free
	,100 - round((nvl( ( mb_max - mb_used_alloc ), 0) / mb_max) * 100, 2) pct_total_used  
from
(
    select 
         tablespace_name
        ,mb_alloc
        ,mb_free_alloc
        ,mb_used_alloc
        ,pct_free_mb_alloc 
        ,pct_used_mb_alloc
        ,CASE WHEN mb_max < mb_alloc THEN mb_alloc ELSE mb_max END mb_max
    from
        (   
            SELECT
                wds_a.tablespace_name tablespace_name,
                round(wds_a.bytes_alloc / 1024 / 1024, 2) mb_alloc,
                round(nvl(wds_b.bytes_free, 0) / 1024 / 1024, 2) mb_free_alloc,
                round((wds_a.bytes_alloc - nvl(wds_b.bytes_free, 0)) / 1024 / 1024, 2) mb_used_alloc,
                round((nvl(wds_b.bytes_free, 0) / wds_a.bytes_alloc) * 100, 2) pct_free_mb_alloc,
                100 - round((nvl(wds_b.bytes_free, 0) / wds_a.bytes_alloc) * 100, 2) pct_used_mb_alloc,
                round(maxbytes / 1048576, 2) mb_max
            FROM
                (
                    SELECT
                        f.tablespace_name,
                        SUM(f.bytes) bytes_alloc,
                        SUM( CASE WHEN maxbytes > bytes THEN maxbytes ELSE bytes END ) maxbytes
                    FROM
                        dba_data_files f
                    GROUP BY
                        tablespace_name
                )  wds_a,
                (
                    SELECT
                        f.tablespace_name,
                        SUM(f.bytes) bytes_free
                    FROM
                        dba_free_space f
                    GROUP BY
                        tablespace_name
                )  wds_b
            WHERE
                wds_a.tablespace_name = wds_b.tablespace_name (+)
            UNION
            SELECT
                wds_h.tablespace_name,
                round(SUM(wds_h.bytes_free + wds_h.bytes_used) / 1048576, 2),
                round(SUM((wds_h.bytes_free + wds_h.bytes_used) - nvl(wds_p.bytes_used, 0)) / 1048576, 2),
                round(SUM(nvl(wds_p.bytes_used, 0)) / 1048576, 2),
                round((SUM((wds_h.bytes_free + wds_h.bytes_used) - nvl(wds_p.bytes_used, 0)) / SUM(wds_h.bytes_used + wds_h.bytes_free)) * 100, 2),
                100 - round((SUM((wds_h.bytes_free + wds_h.bytes_used) - nvl(wds_p.bytes_used, 0)) / SUM(wds_h.bytes_used + wds_h.bytes_free)) * 100, 2),
                round(MAX(wds_h.bytes_used + wds_h.bytes_free) / 1048576, 2)
            FROM
                sys.v_$temp_space_header    wds_h,
                sys.v_$temp_extent_pool     wds_p
            WHERE
                    wds_p.file_id (+) = wds_h.file_id
                AND wds_p.tablespace_name (+) = wds_h.tablespace_name
            GROUP BY
                wds_h.tablespace_name
        )
);
