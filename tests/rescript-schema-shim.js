
if (typeof globalThis.Caml_option === 'undefined') {
    globalThis.Caml_option = {
        valFromOption: (x) => {
            if (x === null || x === undefined || x.BS_PRIVATE_NESTED_SOME_NONE === undefined) {
                return x;
            }
            let depth = x.BS_PRIVATE_NESTED_SOME_NONE;
            if (depth === 0) {
                return undefined;
            } else {
                return {
                    BS_PRIVATE_NESTED_SOME_NONE: depth - 1
                };
            }
        }
    };
}
