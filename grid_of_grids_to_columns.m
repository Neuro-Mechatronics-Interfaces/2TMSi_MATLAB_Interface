function [iRow,iCol] = grid_of_grids_to_columns(bigGridSize, smallGridSize, options)
arguments
    bigGridSize (1,2) {mustBePositive,mustBeInteger} = [16, 16]
    smallGridSize (1,2) {mustBePositive,mustBeInteger} = [8, 8]
    options.TileIndexing {mustBeMember(options.TileIndexing, {'RowMajor','ColumnMajor'})} = 'RowMajor';
end
nSmallElectrodes = smallGridSize(1)*smallGridSize(2);
nRows = bigGridSize(1)/smallGridSize(1);
nCols = bigGridSize(2)/smallGridSize(2);
if (rem(nRows,1)>0) || (rem(nCols,1)>0)
    error("Number of rows/columns of big grid must be evenly divisible by rows/columns of small grid.");
end

tmpRow = cell(nRows,nCols);
tmpCol = cell(nRows,nCols);
switch options.TileIndexing
    case 'RowMajor'
        for ii = 1:nCols
            for ik = 1:nRows
                [tmpRow{ii,ik},tmpCol{ii,ik}] = ind2sub(smallGridSize,(1:nSmallElectrodes)');
                tmpRow{ii,ik} = tmpRow{ii,ik} + nRows*(ii-1);
                tmpCol{ii,ik} = tmpCol{ii,ik} + nCols*(ii-1);
            end
        end

    case 'ColumnMajor'
        for ik = 1:nCols
            for ii = 1:nRows
                [tmpRow{ii,ik},tmpCol{ii,ik}] = ind2sub(smallGridSize,(1:nSmallElectrodes)');
                tmpRow{ii,ik} = tmpRow{ii,ik} + nRows*(ii-1);
                tmpCol{ii,ik} = tmpCol{ii,ik} + nCols*(ii-1);
            end
        end
end
iRow = vertcat(tmpRow{:});
iCol = vertcat(tmpCol{:});

end