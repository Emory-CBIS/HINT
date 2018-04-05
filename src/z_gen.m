 function zv = z_gen(N, m, q)
 % zv = z_gen(N, m, q)
 % Generating sequence of zv given integar N, 0<=N<=m^q-1
 % Sequentially according to m complementation
     if ( N < 0 || N >= m^q )
         disp('error in input N: must be between 0 and m^q-1'); end;
     zv    = zeros(q ,1);
     for i = 1:q
           zv(i) =floor ( N / m^(q-i) );
           N     = N - zv(i)*m^(q-i);
     end;
     zv    = zv + 1;
 end