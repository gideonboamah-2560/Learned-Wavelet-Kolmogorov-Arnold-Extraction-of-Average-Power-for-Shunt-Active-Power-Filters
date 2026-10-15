function [headers, data] = readCsvSimple(path)
%READCSVSIMPLE Minimal CSV reader (Octave has no readtable). Returns
%   headers (cellstr) and data (cell array of rows, each a cellstr of
%   raw field strings -- caller converts numeric fields as needed).
fid = fopen(path, 'r');
headerLine = fgetl(fid);
headers = strsplit(headerLine, ',', 'CollapseDelimiters', false);
data = {};
while true
    l = fgetl(fid);
    if ~ischar(l), break; end
    if isempty(l), continue; end
    data(end+1,:) = strsplit(l, ',', 'CollapseDelimiters', false); %#ok<AGROW>
end
fclose(fid);
end
