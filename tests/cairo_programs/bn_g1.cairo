%builtins range_check bitwise poseidon

from src.bn254.towers.e12 import E12, e12
from src.bn254.towers.e2 import E2, e2
from src.bn254.towers.e6 import E6
from src.bn254.g1 import G1Point, G1PointFull, g1
from starkware.cairo.common.registers import get_fp_and_pc
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_secp.bigint import BigInt3, uint256_to_bigint, bigint_to_uint256
from starkware.cairo.common.cairo_builtins import PoseidonBuiltin, BitwiseBuiltin

func main{range_check_ptr, bitwise_ptr: BitwiseBuiltin*, poseidon_ptr: PoseidonBuiltin*}() {
    alloc_locals;
    let (__fp__, _) = get_fp_and_pc();

    local g1x: BigInt3;
    local g1y: BigInt3;
    local ng1x: BigInt3;
    local ng1y: BigInt3;

    local n: BigInt3;

    %{
        import subprocess
        import random
        import functools
        import re
        from starkware.cairo.common.cairo_secp.secp_utils import split
        P=0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd47
        BN254_ORDER = 21888242871839275222246405745257275088548364400416034343698204186575808495617
        def rgetattr(obj, attr, *args):
            def _getattr(obj, attr):
                return getattr(obj, attr, *args)
            return functools.reduce(_getattr, [obj] + attr.split('.'))

        def rsetattr(obj, attr, val):
            pre, _, post = attr.rpartition('.')
            return setattr(rgetattr(obj, pre) if pre else obj, post, val)

        def fill_element(element:str, value:int):
            s = split(value)
            for i in range(3): rsetattr(ids,element+'.d'+str(i),s[i])
        def parse_fp_elements(input_string:str):
            pattern = re.compile(r'\[([^\[\]]+)\]')
            substrings = pattern.findall(input_string)
            sublists = [substring.split(' ') for substring in substrings]
            sublists = [[int(x) for x in sublist] for sublist in sublists]
            fp_elements = [x[0] + x[1]*2**64 + x[2]*2**128 + x[3]*2**192 for x in sublists]
            return fp_elements

        cmd = ['./tools/gnark/main', 'nG1nG2']+["1", "1"]
        out = subprocess.run(cmd, stdout=subprocess.PIPE).stdout.decode('utf-8')
        fp_elements = parse_fp_elements(out)
        assert len(fp_elements) == 6
        fill_element('g1x', fp_elements[0])
        fill_element('g1y', fp_elements[1])

        inputs=[random.randint(0, BN254_ORDER) for i in range(2)]
        cmd = ['./tools/gnark/main', 'nG1nG2']+[str(x) for x in inputs]
        out = subprocess.run(cmd, stdout=subprocess.PIPE).stdout.decode('utf-8')
        fp_elements = parse_fp_elements(out)
        assert len(fp_elements) == 6
        fill_element('ng1x', fp_elements[0])
        fill_element('ng1y', fp_elements[1])
        fill_element('n', inputs[0])
    %}
    local G: G1Point = G1Point(&g1x, &g1y);
    local nG: G1Point = G1Point(&ng1x, &ng1y);
    g1.assert_on_curve(&G);

    let (res) = g1.scalar_mul(&G, n);

    let db = g1.compute_doubling_slope(G1PointFull(g1x, g1y));
    let sl = g1.compute_slope(G1PointFull(g1x, g1y), G1PointFull(ng1x, ng1y));

    // g1.assert_equal(res, nG);
    return ();
}
