part of texture_packer;
class BinarySearch {
  int min, max, fuzziness, low, high, current;
  bool pot;

  BinarySearch (int min, int max, int fuzziness, bool pot) {
    this.pot = pot;
    this.fuzziness = pot ? 0 : fuzziness;
    this.min = pot ? (Math.log(MathUtils.nextPowerOfTwo(min)) / Math.log(2)).toInt() : min;
    this.max = pot ? (Math.log(MathUtils.nextPowerOfTwo(max)) / Math.log(2)).toInt() : max;
  }

  int reset () {
    low = min;
    high = max;
    current = (low + high) >> 1;//current = (low + high) >>> 1;
    return pot ? Math.pow(2, current).toInt() : current;
  }

  int next (bool result) {
    if (low >= high) return -1;
    if (result)
      low = current + 1;
    else
      high = current - 1;
    current = (low + high) >> 1;//current = (low + high) >>> 1;
    if ((low - high).abs() < fuzziness) return -1;
    return pot ? Math.pow(2, current).toInt()  : current;
  }
}

