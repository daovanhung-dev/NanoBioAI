export const EARLY_ACCESS_GENDERS = [
  'male',
  'female',
  'other',
  'prefer_not_to_say',
] as const;

export type EarlyAccessGender = (typeof EARLY_ACCESS_GENDERS)[number];

export type EarlyAccessCustomer = {
  fullName: string;
  age: string;
  gender: string;
  address: string;
};

export type ValidatedEarlyAccessCustomer = {
  full_name: string;
  age: number;
  gender: EarlyAccessGender;
  address: string;
};

export type CustomerValidation =
  | { valid: true; value: ValidatedEarlyAccessCustomer }
  | { valid: false; field: keyof EarlyAccessCustomer; message: string };

export function validateEarlyAccessCustomer(
  customer: EarlyAccessCustomer,
): CustomerValidation {
  const fullName = customer.fullName.trim();
  if (!fullName || fullName.length > 120) {
    return {
      valid: false,
      field: 'fullName',
      message: 'Vui lòng nhập họ tên (tối đa 120 ký tự).',
    };
  }

  const age = Number(customer.age.trim());
  if (!Number.isInteger(age) || age < 18 || age > 120) {
    return {
      valid: false,
      field: 'age',
      message: 'NanoBio Early Access hiện dành cho người từ 18 tuổi trở lên.',
    };
  }

  if (!EARLY_ACCESS_GENDERS.includes(customer.gender as EarlyAccessGender)) {
    return {
      valid: false,
      field: 'gender',
      message: 'Vui lòng chọn giới tính hoặc “Không muốn trả lời”.',
    };
  }

  const address = customer.address.trim();
  if (!address || address.length > 512) {
    return {
      valid: false,
      field: 'address',
      message: 'Vui lòng nhập địa chỉ (tối đa 512 ký tự).',
    };
  }

  return {
    valid: true,
    value: {
      full_name: fullName,
      age,
      gender: customer.gender as EarlyAccessGender,
      address,
    },
  };
}
