const { sumar } = require('./index');

describe('Tests de ejemplo', () => {
  test('sumar dos números', () => {
    expect(sumar(2, 3)).toBe(5);
  });

  test('sumar números negativos', () => {
    expect(sumar(-1, -1)).toBe(-2);
  });

  test('sumar cero', () => {
    expect(sumar(0, 5)).toBe(5);
  });
});
