% preconditions 
nVisit = 2;
nCol = 3;
mapset1 = cell(nVisit, nCol);
for i = 1:nVisit
    for j = 1:nCol
        mapset1{i, j} = rand(5, 5);
    end
end
validVoxels1 = find(~isnan(mapset1{1}));

%% Test 1: Grp viewer, standard Z-normalization
correctAnswerTest1 = cell(nVisit, nCol);
for i = 1:nVisit
    for j = 1:nCol
        correctAnswerTest1{i, j} =  (mapset1{i, j} - mean( mapset1{i, j}(:) )) ./ std(mapset1{i, j}(:));
    end
end
ansTest1 = generate_zscore_maps('grp', 1, mapset1, '', validVoxels1, 999);
assert( isequal(ansTest1, correctAnswerTest1) )

%% Test 2: Grp viewer, undoing Z-normalization
ansTest2 = generate_zscore_maps('grp', 0, mapset1, '', validVoxels1, 999);
assert( isequal(ansTest2, mapset1) )

%% Test 3: Beta Viewer, no contrast
generate_zscore_maps('Effect View', 1, mapset1, '', validVoxels1, 999);






