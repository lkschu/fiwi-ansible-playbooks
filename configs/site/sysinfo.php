<html>
<head>
  <title>
    <npsobj name="sysinfo-title" insertvalue="var"/>
  </title>
</head>
<body>
<?php $output=shell_exec('/usr/local/bin/procsys.sh'); echo "<pre>$output</pre>"; ?>
</body>

</html>
