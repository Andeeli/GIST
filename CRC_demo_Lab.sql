SELECT m.[BIRTH_DATE]
      ,datediff(year, m.BIRTH_DATE, d.admit_date) as dx_age
      ,m.[SEX]
      ,m.[HISPANIC]
      ,m.[RACE]
      ,m.[ZIP_CODE]
      ,d.source
      ,d.dx
      ,pl.platelet
      ,pl.plt_unit
      ,bb.bilirubin
      ,bb.bb_unit
      ,ct.creatinine_serum
      ,ct.ct_unit
  FROM [ONEFLDW_PCORI_20180726_CERT].[dbo].[DEMOGRAPHIC] m
left join (
  select pl1.patid, pl1.result_num as platelet, pl1.result_unit as plt_unit from [ONEFLDW_PCORI_20180726_CERT].[dbo].[LAB_RESULT_CM] pl1
  join (
        select patid, max(SPECIMEN_DATE) as max_date, max(specimen_time) as max_time from [ONEFLDW_PCORI_20180726_CERT].[dbo].[LAB_RESULT_CM]
        where LAB_LOINC = '26515-7' and result_num is not null
        group by patid
        ) pl2 on pl1.patid = pl2.patid and pl1.SPECIMEN_DATE=pl2.max_date and pl1.specimen_time = pl2.max_time
  where LAB_LOINC = '26515-7'
  ) pl on m.patid = pl.patid
left join (
  select bb1.patid, bb1.result_num as bilirubin, bb1.result_unit as bb_unit from [ONEFLDW_PCORI_20180726_CERT].[dbo].[LAB_RESULT_CM] bb1
  join (
        select patid, max(SPECIMEN_DATE) as max_date, max(specimen_time) as max_time from [ONEFLDW_PCORI_20180726_CERT].[dbo].[LAB_RESULT_CM]
        where LAB_LOINC = '1975-2' and result_num is not null
        group by patid
        ) bb2 on bb1.patid = bb2.patid and bb1.SPECIMEN_DATE=bb2.max_date and bb1.specimen_time = bb2.max_time
  where LAB_LOINC = '1975-2'
  ) bb on m.patid = bb.patid
left join (
  select ct1.patid, ct1.result_num as creatinine_serum, ct1.result_unit as ct_unit from [ONEFLDW_PCORI_20180726_CERT].[dbo].[LAB_RESULT_CM] ct1
  join (
        select patid, max(SPECIMEN_DATE) as max_date, max(specimen_time) as max_time from [ONEFLDW_PCORI_20180726_CERT].[dbo].[LAB_RESULT_CM]
        where LAB_LOINC = '2160-0' and result_num is not null
        group by patid
        ) ct2 on ct1.patid = ct2.patid and ct1.SPECIMEN_DATE=ct2.max_date and ct1.specimen_time = ct2.max_time
  where LAB_LOINC = '2160-0'
  ) ct on m.patid = ct.patid
left join (
  select d1.patid, d1.admit_date, d1.source, d1.dx from [ONEFLDW_PCORI_20180726_CERT].[dbo].[DIAGNOSIS] d1
  join (
    select patid, min(admit_date) as min_date from [ONEFLDW_PCORI_20180726_CERT].[dbo].[DIAGNOSIS]
    where ((replace(dx,'.','') in ('1530','1531','1532','1533','1534','1535','1536','1537',
      '1538','1539','1540','1541','1542','1543','1548') and dx_type='09') or 
      (replace(dx, '.','') in ('C180','C181','C182','C183','C184','C185','C186','C187',
        'C188','C189','C199','C209','C210','C211','C212','C218') and dx_type='10'))
      and year(admit_date) >=2012 and source <> 'FLM'
    group by patid
    ) d2 on d1.patid = d2.patid and d1.admit_date = d2.min_date
      where ((replace(dx,'.','') in ('1530','1531','1532','1533','1534','1535','1536','1537',
      '1538','1539','1540','1541','1542','1543','1548') and dx_type='09') or 
      (replace(dx, '.','') in ('C180','C181','C182','C183','C184','C185','C186','C187',
        'C188','C189','C199','C209','C210','C211','C212','C218') and dx_type='10'))
      and year(admit_date) >=2012 and source <> 'FLM'
) d on m.patid = d.patid
where m.patid in (
    SELECT distinct patid FROM [ONEFLDW_PCORI_20180726_CERT].[dbo].[DIAGNOSIS]
    where ((replace(dx,'.','') in ('1530','1531','1532','1533','1534','1535','1536','1537',
      '1538','1539','1540','1541','1542','1543','1548') and dx_type='09') or 
      (replace(dx, '.','') in ('C180','C181','C182','C183','C184','C185','C186','C187',
        'C188','C189','C199','C209','C210','C211','C212','C218') and dx_type='10'))
      and year(admit_date) >=2012 and source <> 'FLM'
  )