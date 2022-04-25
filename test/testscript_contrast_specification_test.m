% preconditions Tests 1-2
nVisit = 5;
P = 3;
c = [1; -1;  0];
ctrResult = createContrast(c, P, nVisit);

%
% Test 1: Simple contrast at first visit (longitudinal)
%
% depends on: preconditions only

%% Test 1A
correctAnswerTest1 = [1; -1; 0; zeros(4*(nVisit-1), 1)];
assert( isequal(ctrResult(:, 1), correctAnswerTest1) )

%
% Test 2: Simple contrast at second visit (longitudinal)
%
% depends on: preconditions only

%% Test 2A
correctAnswerTest2 = [0; 0; 0; 0; 1; -1; 0; zeros(4*(nVisit-2), 1)];
assert( isequal(ctrResult(:, 2), correctAnswerTest2) )

%
% Test 3: Cross-visit contrast
%
% depends on: preconditions only

% preconditions
nVisit=3;
P = 2;
c = [1; 0; -1; 0; 0; 0];

%% Test 3A
correctAnswerTest3 = [1; 0; 0; -1; 0; 0; 0; 0];
assert( isequal(createContrast(c, P, nVisit), correctAnswerTest3) )
