<html>

<!--#include file="DbConnOpen.asp"-->

<!--#include file="GetUser.asp"-->

<!--#include file="HighlightCell.asp"-->

<!--#include file="IASUtil.asp"-->

<!--#include file="Style.asp"-->

<!--#include file="ToolTip.asp"-->

 

<head>

<meta http-equiv="Content-Language" content="en-us">

<meta http-equiv="Content-Type" content="text/html; charset=windows-1252">

<title>SAP Closing Report for Finance</title>

<link rel="STYLESHEET" type="text/css" href="../calendar.css">

<script language="JavaScript" src="../calendar.js" type="text/javascript"></script>

<style type="text/css">

.style1 {

                font-size: x-small;

                color: #800000;

}

</style>

</head>

<%

MsgStr = ""

BtnCreateSAP = Request("BtnCreateSAP")

 

If genFinRep And BtnCreateSAP <> "" Then

 

                fromDate = Request("FromDate")

                If fromDate= "" Then

                               fromDate = Date

                End If

 

                toDate = Request("ToDate")

                If toDate = "" Then

                               toDate = Date

                End If

                toDate = DateAdd("d", CDate(toDate), 1)

               

                fromDate = Month(fromDate) &"-"& Day(fromDate) &"-"& Year(fromDate)

                toDate = Month(toDate) &"-"& Day(toDate) &"-"& Year(toDate)

 

                'If CDate(fromDate) > CDate(toDate) Then

                               'MsgStr = "From Date must be before To Date"

                               'response.write MsgStr

                'End If

 

                Set xla = CreateObject("SoftArtisans.ExcelWriter")

                xla.open "E:\XLTemplates\LIMSDash\LIMSMonthEndSAP.xls"

                Set Cells = xla.Worksheets("ClosingSAP").Cells

 

                'SQLStr = "SELECT ver_an.M_COST_CENTER AS senderCostCenter, tst.ANALYSIS, ver_an.CHARGECODE AS actType, ver_an.IDENTITY AS anCode, "

 

                SQLStr = "SELECT '000000' || senderCostCenter AS senderCostCenter, acttype, SUBSTR(WBS, 1, (LENGTH(WBS)) - 2) || '.' || SUBSTR(WBS, -2) AS WBS, Sum(SampleCnt) AS SampleCnt, Sum(ResSampleCnt) AS ResSampleCnt, Sum(TotalHours) AS TotalHours, Sum(quantity) AS quantity "

                SQLStr = SQLStr & "FROM ("

                SQLStr = SQLStr & "SELECT ver_an.M_COST_CENTER AS senderCostCenter, ver_an.CHARGECODE AS actType, "

               SQLStr = SQLStr & "'R0.' || sgact.COST_CENTER || '.' || sgact.IDENTITY as WBS, "

               SQLStr = SQLStr & "Sum(res.m_sampcnt) AS SampleCnt, Sum(res.ResSampCnt) AS ResSampleCnt, NVL(Sum(Hours), 0) AS TotalHours, "

    SQLStr = SQLStr & "CASE "

    SQLStr = SQLStr & "WHEN ver_an.CHARGECODE LIKE '%LIMSH' THEN Sum(Hours) "

    SQLStr = SQLStr & "WHEN ver_an.CHARGECODE NOT LIKE '%LIMSH' THEN "

    SQLStr = SQLStr & "  CASE "

    SQLStr = SQLStr & "    WHEN Sum(res.m_sampcnt) = 0 THEN Sum(res.ResSampCnt) "

    SQLStr = SQLStr & "    ELSE "

    SQLStr = SQLStr & "      CASE "

    SQLStr = SQLStr & "        WHEN Sum(res.m_sampcnt) > Sum(res.ResSampCnt) THEN Sum(res.m_sampcnt) "

    SQLStr = SQLStr & "        ELSE Sum(res.ResSampCnt) "

    SQLStr = SQLStr & "      END "

    SQLStr = SQLStr & "  END "

    SQLStr = SQLStr & "END AS quantity "

 

                SQLFROMStr = "FROM (SELECT TEST_NUMBER, SUM(TEST_TIME_SPENT) AS Hours FROM PROD11_2.SG_OPERATOR_TAT GROUP BY TEST_NUMBER) op_tat RIGHT JOIN "

                SQLFROMStr = SQLFROMStr & "((SELECT IDENTITY, M_COST_CENTER, CHARGECODE, MAX(Analysis_Version) AS Ver FROM PROD11_2.VERSIONED_ANALYSIS WHERE REMOVEFLAG = 'F' GROUP BY IDENTITY, M_COST_CENTER, CHARGECODE) ver_an INNER JOIN "

                SQLFROMStr = SQLFROMStr & "(PROD11_2.SG_NWRDC_SCNTSALL res INNER JOIN "

                SQLFROMStr = SQLFROMStr & "(PROD11_2.TEST tst INNER JOIN "

                SQLFROMStr = SQLFROMStr & "(PROD11_2.JOB_HEADER jobh INNER JOIN "

                SQLFROMStr = SQLFROMStr & "PROD11_2.SG_ACCOUNT sgact "

                SQLFROMStr = SQLFROMStr & "ON jobh.M_ACCOUNT = sgact.IDENTITY INNER JOIN PROD11_2.SAMPLE samp "

                SQLFROMStr = SQLFROMStr & "ON samp.JOB_NAME = jobh.JOB_NAME) "

                SQLFROMStr = SQLFROMStr & "ON tst.SAMPLE = samp.ID_NUMERIC) ON res.TEST_NUMBER = tst.TEST_NUMBER) ON ver_an.IDENTITY = tst.ANALYSIS) "

                SQLFROMStr = SQLFROMStr & "ON op_tat.TEST_NUMBER = tst.TEST_NUMBER "

               

                SQLWhereStr = "WHERE jobh.DATE_AUTHORISED BETWEEN TO_DATE('"& fromDate &"','mm-dd-yyyy') AND TO_DATE('"& toDate &"','mm-dd-yyyy') "

                SQLWhereStr = SQLWhereStr & "AND ((jobh.M_CENTER)='NWRDC') AND ((jobh.JOB_STATUS) In ('A')) "

                SQLWhereStr = SQLWhereStr & "GROUP BY sgact.IDENTITY, sgact.COST_CENTER, ver_an.M_COST_CENTER, ver_an.CHARGECODE "

 

                SQLStr = SQLStr & SQLFromStr & SQLWhereStr

 

                USQLStr = "UNION SELECT '000000' || ver_an.M_COST_CENTER AS senderCostCenter, ver_an.CHARGECODE AS actType, "

               USQLStr = USQLStr & "'R0.' || sgact.COST_CENTER || '.' || sgact.IDENTITY as WBS, "

               USQLStr = USQLStr & "Sum(res.m_sampcnt) AS SampleCnt, Sum(res.ResSampCnt) AS ResSampleCnt, Sum(op_tat.Hours) AS TotalHours, "

    USQLStr = USQLStr & "CASE "

    USQLStr = USQLStr & "WHEN ver_an.CHARGECODE LIKE '%LIMSH%' THEN SUM(op_tat.Hours) "

    USQLStr = USQLStr & "WHEN ver_an.CHARGECODE NOT LIKE '%LIMSH%' THEN "

    USQLStr = USQLStr & "  CASE "

    USQLStr = USQLStr & "    WHEN Sum(res.ResSampCnt) = 0 THEN "

    USQLStr = USQLStr & "      CASE "

    USQLStr = USQLStr & "        WHEN Sum(res.m_sampcnt) = 0 THEN 1 "

    USQLStr = USQLStr & "        ELSE Sum(res.m_sampcnt) "

    USQLStr = USQLStr & "      END "

    USQLStr = USQLStr & "    ELSE Sum(res.ResSampCnt) "

    USQLStr = USQLStr & "  END "

    USQLStr = USQLStr & "END AS quantity "

 

                USQLFROMStr = "FROM (SELECT TEST_NUMBER, SUM(TEST_TIME_SPENT) AS Hours FROM PROD11_2.SG_OPERATOR_TAT GROUP BY TEST_NUMBER) op_tat RIGHT JOIN "

                USQLFROMStr = USQLFROMStr & "((SELECT IDENTITY, M_COST_CENTER, CHARGECODE, MAX(Analysis_Version) AS Ver FROM PROD11_2.VERSIONED_ANALYSIS WHERE REMOVEFLAG = 'F' GROUP BY IDENTITY, M_COST_CENTER, CHARGECODE) ver_an INNER JOIN "

                USQLFROMStr = USQLFROMStr & "(PROD11_2.SG_NWRDC_SCNTSALL res INNER JOIN "

                USQLFROMStr = USQLFROMStr & "(PROD11_2.C_TEST ctst INNER JOIN "

                USQLFROMStr = USQLFROMStr & "(PROD11_2.C_JOB_HEADER cjobh INNER JOIN "

                USQLFROMStr = USQLFROMStr & "PROD11_2.SG_ACCOUNT sgact "

                USQLFROMStr = USQLFROMStr & "ON cjobh.M_ACCOUNT = sgact.IDENTITY INNER JOIN PROD11_2.C_SAMPLE csamp "

                USQLFROMStr = USQLFROMStr & "ON csamp.JOB_NAME = cjobh.JOB_NAME) "

                USQLFROMStr = USQLFROMStr & "ON ctst.SAMPLE = csamp.ID_NUMERIC) ON res.TEST_NUMBER = ctst.TEST_NUMBER) ON ver_an.IDENTITY = ctst.ANALYSIS) "

                USQLFROMStr = USQLFROMStr & "ON op_tat.TEST_NUMBER = ctst.TEST_NUMBER "

               

                USQLWhereStr = "WHERE cjobh.DATE_AUTHORISED BETWEEN TO_DATE('"& fromDate &"','mm-dd-yyyy') AND TO_DATE('"& toDate &"','mm-dd-yyyy') "

                USQLWhereStr = USQLWhereStr & "AND ((cjobh.M_CENTER)='NWRDC') AND ((cjobh.JOB_STATUS) In ('A')) "

                USQLWhereStr = USQLWhereStr & "GROUP BY sgact.IDENTITY, sgact.COST_CENTER, ver_an.M_COST_CENTER, ver_an.CHARGECODE "

 

                USQLStr = USQLStr & USQLFromStr & USQLWhereStr

                SQLStr = SQLStr & USQLStr

 

                SQLStr = SQLStr & ") "

                SQLStr = SQLStr & "GROUP BY senderCostCenter, acttype, WBS, quantity "

                SQLStr = SQLStr & "HAVING quantity > 0 "

 

                SQLStr = SQLStr & "ORDER BY senderCostCenter, WBS"

 

                'response.write SQLStr

 

                Set Rs = oConn.Execute(SQLStr)

                currow = 2           'change this to 1 if header line in XL not needed

               

                'xla.Worksheets("ClosingSAP").Cells(1,11).Value=SQLStr

               

                'xla.Worksheets("ClosingSAP").Cells(1,7).Value="Analysis"

                'xla.Worksheets("ClosingSAP").Cells(1,8).Value="SCnt"

                'xla.Worksheets("ClosingSAP").Cells(1,9).Value="RSCnt"

                'xla.Worksheets("ClosingSAP").Cells(1,10).Value="Hours"

 

                While Not Rs.EOF

                               senderCostCenter = Rs("senderCostCenter")

                               actType = Rs("actType")

                               WBS                      = Rs("WBS")

                               If Not IsNull(Rs("quantity")) Then

                                               quantity = Rs("quantity")

                               Else

                                               quantity = 0

                               End If

                               SampleCnt = Rs("SampleCnt")

                               ResSampleCnt = Rs("ResSampleCnt")

                               TotalHours = Rs("TotalHours")

                              

                               'AnalysisCode = Rs("anCode")

                              

                               xla.Worksheets("ClosingSAP").Cells(currow,1).Value=senderCostCenter

                               xla.Worksheets("ClosingSAP").Cells(currow,2).Value=actType

                               'xla.Worksheets("ClosingSAP").Cells(currow,3).Value=ccreceiver

                               'xla.Worksheets("ClosingSAP").Cells(currow,4).Value=ioreceiver

                               xla.Worksheets("ClosingSAP").Cells(currow,5).Value=WBS

                               xla.Worksheets("ClosingSAP").Cells(currow,6).Value=quantity

                              

                               'xla.Worksheets("ClosingSAP").Cells(currow,7).Value=AnalysisCode

                               'xla.Worksheets("ClosingSAP").Cells(currow,8).Value=SampleCnt

                               'xla.Worksheets("ClosingSAP").Cells(currow,9).Value=ResSampleCnt

                               'xla.Worksheets("ClosingSAP").Cells(currow,10).Value=TotalHours

                              

                               Rs.MoveNext

                               currow = currow + 1

                Wend

               

                Rs.Close

 

                'stream the file to the user

                Response.Clear

                Set Cells = Nothing

                xla.Save "LIMSMonthEndSAP.xls", 1

                Set xla = Nothing

 

                MsgStr = "Ok."

               

                Set Rs = Nothing

               

Else 'else if no button

                               MsgStr = ""

End If

%>

 

<body style="font-family: Verdana; font-size: 8pt">

<%

If genFinRep Then %>

                <form method="POST" name="form" action="FinRepSAP.asp">

                              

                               <table cellspacing="0" cellpadding="0">

                                               <tr>

                                                               <td colspan="4" align="left">

                                                                               Please choose a date range for the report

                                                               </td>

                                               </tr>

                                               <tr>

                                                               <td>&nbsp;</td>                           

                                               </tr>

                                               <tr>

                                                               <td>

                                                                               From:<input type="text" name="FromDate" size="20" style="font-family: Verdana; font-size: 10px" value="<%=FromDate%>">

                                                                               <a href="javascript: void(0);" onmouseover="if (timeoutId) clearTimeout(timeoutId);window.status='Show Calendar';return true;" onmouseout="if (timeoutDelay) calendarTimeout();window.status='';" onclick="g_Calendar.show(event,'form.FromDate',false); return false;">

                                                                                              <img src="../images/calendar.gif" name="imgCalendar" border="0" alt="Show Calendar">

                                                                               </a>

                                                               </td>

                                                               <td style="width: 10px">&nbsp;</td>

                                                               <td>

                                                                               To:<input type="text" name="ToDate" size="20" style="font-family: Verdana; font-size: 10px" value="<%=ToDate%>">

                                                                               <a href="javascript: void(0);" onmouseover="if (timeoutId) clearTimeout(timeoutId);window.status='Show Calendar';return true;" onmouseout="if (timeoutDelay) calendarTimeout();window.status='';" onclick="g_Calendar.show(event,'form.ToDate',false); return false;">

                                                                                              <img src="../images/calendar.gif" name="imgCalendar" border="0" alt="Show Calendar">

                                                                               </a>

                                                               </td>

                                                               <td style="width: 10px">&nbsp;</td>

                                               </tr>

                                               <tr>

                                                               <td>&nbsp;</td>                           

                                               </tr>

                                               <tr>

                                                               <td colspan="4" align="center">

                                                                               <input type="submit" value="Create Month End Report" name="BtnCreateSAP" style="font-family: Verdana; font-size: 10px">

                                                               </td>                                                  

                                               </tr>

                                               <tr>

                                                               <td>&nbsp;<%=MsgStr%></td>               

                                               </tr>

                               </table>

                &nbsp;

                </form>

<%

Else %>

<p class="style1"><strong>You have no permissions on this page!</strong></p>

<%

End If %>

</body>

<!--#include file="DbConnClose.asp"-->

</html>