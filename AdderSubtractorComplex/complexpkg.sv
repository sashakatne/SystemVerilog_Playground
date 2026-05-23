package complexpkg;

    typedef struct {
        shortreal real_part;
        shortreal imaginary_part;
    } complex;

    function complex AddComplex(input complex M, N);
        complex result;
        result.real_part = M.real_part + N.real_part;
        result.imaginary_part = M.imaginary_part + N.imaginary_part;
        return result;
    endfunction

    function complex MultComplex(input complex M, N);
        complex result;
        result.real_part = (M.real_part * N.real_part) -
                           (M.imaginary_part * N.imaginary_part);
        result.imaginary_part = (M.real_part * N.imaginary_part) +
                                (M.imaginary_part * N.real_part);
        return result;
    endfunction

    function complex CreateComplex(input shortreal RealPart, ImaginaryPart);
        complex result;
        result.real_part = RealPart;
        result.imaginary_part = ImaginaryPart;
        return result;
    endfunction

    function void PrintComplex(input complex C);
        $display("(r: %f, i: %f)", C.real_part, C.imaginary_part);
    endfunction

    function void ComplexToComponents(
        input  complex   C,
        output shortreal RealPart,
        output shortreal ImaginaryPart
    );
        RealPart = C.real_part;
        ImaginaryPart = C.imaginary_part;
    endfunction

endpackage
