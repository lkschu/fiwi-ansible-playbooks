<html>
<head>
  <title>
    <npsobj name="sysinfo-title" insertvalue="var"/>
  </title>
  <style type="text/css">
    body {
        font-family: sans-serif !important;
    	background: #f8f8f8;
    	padding: 15px  0px 5px 0px;
        margin: 0px 33px 0px 33px;
    	color: #333;
        border-top-style: double;
        border-bottom-style: double;
        border-color: #333;
    	}
  </style>
</head>
<body>
<?php $output=shell_exec('/usr/local/bin/procsys.sh'); echo "<pre>$output</pre>"; ?>
</body>

</html>
