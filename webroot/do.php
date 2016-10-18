<?php
	$hostname = gethostbyaddr($_SERVER['REMOTE_ADDR']);
	$prank = isset($_GET['prank']);

	$rules_file = 'bootstrap_rules.txt';

	function error($cause) {
		include 'scripts/error.sh';
		exit();
	}

	$fd = fopen($rules_file, 'r');

	if (! $fd)
		error('Could not open ' . $rules_file);

	while (($line = fgets($fd)) !== false) {

		# Skip comments
		if (preg_match('/^#/', $line))
			continue;

		# Skip empty lines
		if (preg_match('/^$/', $line))
			continue;

		# Split by any whitespace
		$fields = preg_split('/\s+/', $line);

		# Skip lines with less than 2 fields
		if (count($fields) < 4) # 3rd element is an empty string
			continue;

		$type = $fields[0];
		$value = $fields[1];
		$script  = $fields[2];

		switch ($type) {
			case 'hostname':

				if ( ! preg_match('/' . $value . '/', $hostname))
					continue 2;
				break;

			case 'option':
				if ( ! isset($_GET[$value]))
					continue 2;
				break;
		}

		$file = 'scripts/' . $script;
		if (file_exists($file)) {
			include $file;
			exit();
		} else {
			error('Could not find file ' . $file);
		}


	}

	# If it arrives here no matching rule was found
	include 'scripts/nop.sh';
