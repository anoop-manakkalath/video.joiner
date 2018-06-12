
shared String findFileName(String file) {
	return file.substring(0, file.lastIndexOf("."));
}

shared String findFileExt(String file) {
	return file.substring(file.lastIndexOf("."), file.size);
}

shared String convertToPosixFileName(String fileName) {
	value builder = StringBuilder();
	{ String+ } strings  = fileName.split();
	for (i -> string in strings.indexed) {
		builder.append(string);
		if (i < strings.size -1) {
			builder.append("\\ ");
		}
	}
	return builder.string;
}