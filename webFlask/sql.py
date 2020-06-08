def query(startDate,endDate):
    """
    TABLE MAPPING = LIMS -> SGRNA DB BD PLATFORM


    PROD11_2.SG_OPERATOR_TAT = sgr_north_america_lims.sg_operator_tat_raw
    PROD11_2.VERSIONED_ANALYSIS = sgr_north_america_lims.versioned_analysis_raw
    PROD11_2.SG_NWRDC_SCNTSALL = sgr_north_america_lims.sg_nwrdc_scntsall_raw
    PROD11_2.SG_ACCOUNT = sgr_north_america_lims.sg_account_raw


    PROD11_2.C_TEST = sgr_north_america_lims.ods_c_test_raw
    PROD11_2.C_JOB_HEADER = sgr_north_america_lims.ods_c_job_header_raw
    PROD11_2.TEST = sgr_north_america_lims.ods_test_raw
    PROD11_2.JOB_HEADER = sgr_north_america_lims.ods_job_header_raw
    PROD11_2.C_SAMPLE = sgr_north_america_lims.ods_c_sample_raw
    """

    #extract from ASP file used in the former website
    SQLStr = "SELECT '000000' || senderCostCenter AS senderCostCenter, acttype, SUBSTR(WBS, 1, (LENGTH(WBS)) - 2) || '.' || SUBSTR(WBS, -2) AS WBS, Sum(SampleCnt) AS SampleCnt, Sum(ResSampleCnt) AS ResSampleCnt, Sum(TotalHours) AS TotalHours, Sum(quantity) AS quantity "
    SQLStr +=   "FROM ("
    SQLStr +=   "SELECT ver_an.M_COST_CENTER AS senderCostCenter, ver_an.CHARGECODE AS actType, "
    SQLStr +=   "'R0.' || sgact.COST_CENTER || '.' || sgact.IDENTITY as WBS, "
    SQLStr +=   "Sum(res.m_sampcnt) AS SampleCnt, Sum(res.ResSampCnt) AS ResSampleCnt, NVL(Sum(Hours), 0) AS TotalHours, "
    SQLStr +=   "CASE "
    SQLStr +=   "WHEN ver_an.CHARGECODE LIKE '%LIMSH' THEN Sum(Hours) "
    SQLStr +=   "WHEN ver_an.CHARGECODE NOT LIKE '%LIMSH' THEN "
    SQLStr +=   "  CASE "
    SQLStr +=   "    WHEN Sum(res.m_sampcnt) = 0 THEN Sum(res.ResSampCnt) "
    SQLStr +=   "    ELSE "
    SQLStr +=   "      CASE "
    SQLStr +=   "        WHEN Sum(res.m_sampcnt) > Sum(res.ResSampCnt) THEN Sum(res.m_sampcnt) "
    SQLStr +=   "        ELSE Sum(res.ResSampCnt) "
    SQLStr +=   "      END "
    SQLStr +=   "  END "
    SQLStr +=   "END AS quantity "


    SQLFROMStr = "FROM (SELECT TEST_NUMBER, SUM(TEST_TIME_SPENT) AS Hours FROM " + PROD11_2.SG_OPERATOR_TAT +"GROUP BY TEST_NUMBER) op_tat RIGHT JOIN "
    SQLFROMStr += "((SELECT IDENTITY, M_COST_CENTER, CHARGECODE, MAX(Analysis_Version) AS Ver FROM"+ PROD11_2.VERSIONED_ANALYSIS +"WHERE REMOVEFLAG = 'F' GROUP BY IDENTITY, M_COST_CENTER, CHARGECODE) ver_an INNER JOIN "
    SQLFROMStr += "("+PROD11_2.SG_NWRDC_SCNTSALL +"res INNER JOIN "
    SQLFROMStr += "("+PROD11_2.TEST +"tst INNER JOIN "
    SQLFROMStr += "("+ PROD11_2.JOB_HEADER +"jobh INNER JOIN "
    SQLFROMStr += ""+PROD11_2.SG_ACCOUNT +"sgact "
    SQLFROMStr += "ON jobh.M_ACCOUNT = sgact.IDENTITY INNER JOIN PROD11_2.SAMPLE samp "
    SQLFROMStr += "ON samp.JOB_NAME = jobh.JOB_NAME) "
    SQLFROMStr += "ON tst.SAMPLE = samp.ID_NUMERIC) ON res.TEST_NUMBER = tst.TEST_NUMBER) ON ver_an.IDENTITY = tst.ANALYSIS) "
    SQLFROMStr += "ON op_tat.TEST_NUMBER = tst.TEST_NUMBER "



    SQLWhereStr = "WHERE jobh.DATE_AUTHORISED BETWEEN TO_DATE('"+ startDate +"','mm-dd-yyyy') AND TO_DATE('"+ endDate +"','mm-dd-yyyy') "
    SQLWhereStr += "AND ((jobh.M_CENTER)='NWRDC') AND ((jobh.JOB_STATUS) In ('A')) "
    SQLWhereStr += "GROUP BY sgact.IDENTITY, sgact.COST_CENTER, ver_an.M_COST_CENTER, ver_an.CHARGECODE "

    SQLStr += SQLFROMStr + SQLWhereStr


    USQLStr = "UNION SELECT '000000' || ver_an.M_COST_CENTER AS senderCostCenter, ver_an.CHARGECODE AS actType, "
    USQLStr += "'R0.' || sgact.COST_CENTER || '.' || sgact.IDENTITY as WBS, "
    USQLStr += "Sum(res.m_sampcnt) AS SampleCnt, Sum(res.ResSampCnt) AS ResSampleCnt, Sum(op_tat.Hours) AS TotalHours, "
    USQLStr += "CASE "
    USQLStr += "WHEN ver_an.CHARGECODE LIKE '%LIMSH%' THEN SUM(op_tat.Hours) "
    USQLStr += "WHEN ver_an.CHARGECODE NOT LIKE '%LIMSH%' THEN "
    USQLStr += "  CASE "
    USQLStr += "    WHEN Sum(res.ResSampCnt) = 0 THEN "
    USQLStr += "      CASE "
    USQLStr += "        WHEN Sum(res.m_sampcnt) = 0 THEN 1 "
    USQLStr += "        ELSE Sum(res.m_sampcnt) "
    USQLStr += "      END "
    USQLStr += "    ELSE Sum(res.ResSampCnt) "
    USQLStr += "  END "
    USQLStr += "END AS quantity "


    USQLFROMStr = "FROM (SELECT TEST_NUMBER, SUM(TEST_TIME_SPENT) AS Hours FROM "+ PROD11_2.SG_OPERATOR_TAT + "GROUP BY TEST_NUMBER) op_tat RIGHT JOIN "
    USQLFROMStr += "((SELECT IDENTITY, M_COST_CENTER, CHARGECODE, MAX(Analysis_Version) AS Ver FROM "+ PROD11_2.VERSIONED_ANALYSIS +"WHERE REMOVEFLAG = 'F' GROUP BY IDENTITY, M_COST_CENTER, CHARGECODE) ver_an INNER JOIN "
    USQLFROMStr += "("+PROD11_2.SG_NWRDC_SCNTSALL +"res INNER JOIN "
    USQLFROMStr += "("+PROD11_2.C_TEST +"ctst INNER JOIN "
    USQLFROMStr += "(" +PROD11_2.C_JOB_HEADER +" cjobh INNER JOIN "
    USQLFROMStr += ""+PROD11_2.SG_ACCOUNT +" sgact"
    USQLFROMStr += "ON cjobh.M_ACCOUNT = sgact.IDENTITY INNER JOIN "+PROD11_2.C_SAMPLE+ " csamp" 
    USQLFROMStr += "ON csamp.JOB_NAME = cjobh.JOB_NAME) "
    USQLFROMStr += "ON ctst.SAMPLE = csamp.ID_NUMERIC) ON res.TEST_NUMBER = ctst.TEST_NUMBER) ON ver_an.IDENTITY = ctst.ANALYSIS) "
    USQLFROMStr += "ON op_tat.TEST_NUMBER = ctst.TEST_NUMBER "


    USQLWhereStr = "WHERE cjobh.DATE_AUTHORISED BETWEEN TO_DATE('"& startDate &"','mm-dd-yyyy') AND TO_DATE('"& endDate &"','mm-dd-yyyy') "
    USQLWhereStr += "AND ((cjobh.M_CENTER)='NWRDC') AND ((cjobh.JOB_STATUS) In ('A')) "
    USQLWhereStr += "GROUP BY sgact.IDENTITY, sgact.COST_CENTER, ver_an.M_COST_CENTER, ver_an.CHARGECODE "

    USQLStr += USQLFROMStr & USQLWhereStr
    SQLStr += USQLStr


    SQLStr += ") "
    SQLStr += "GROUP BY senderCostCenter, acttype, WBS, quantity "
    SQLStr += "HAVING quantity > 0 "


    SQLStr += "ORDER BY senderCostCenter, WBS"

    query = SQLStr

    result = makequery(query)
    return result



def makequery(query):

     
    return result