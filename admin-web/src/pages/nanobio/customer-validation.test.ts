import { describe, expect, it } from 'vitest';
import { validateEarlyAccessCustomer } from './customer-validation';

const validCustomer = {
  fullName: '  Nguyễn An  ',
  age: '24',
  gender: 'prefer_not_to_say',
  address: '  Quận 1, Thành phố Hồ Chí Minh  ',
};

describe('Early Access customer validation', () => {
  it('normalizes the required customer fields for the server payload', () => {
    expect(validateEarlyAccessCustomer(validCustomer)).toEqual({
      valid: true,
      value: {
        full_name: 'Nguyễn An',
        age: 24,
        gender: 'prefer_not_to_say',
        address: 'Quận 1, Thành phố Hồ Chí Minh',
      },
    });
  });

  it.each(['17', '18.5', '121', 'abc', ''])('requires age 18 or older and a whole number (%s)', (age) => {
    expect(validateEarlyAccessCustomer({ ...validCustomer, age })).toMatchObject({
      valid: false,
      field: 'age',
    });
  });

  it('requires a valid gender selection, name, and address', () => {
    expect(validateEarlyAccessCustomer({ ...validCustomer, gender: '' })).toMatchObject({ valid: false, field: 'gender' });
    expect(validateEarlyAccessCustomer({ ...validCustomer, fullName: ' ' })).toMatchObject({ valid: false, field: 'fullName' });
    expect(validateEarlyAccessCustomer({ ...validCustomer, address: ' ' })).toMatchObject({ valid: false, field: 'address' });
  });
});
