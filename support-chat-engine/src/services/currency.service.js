const { pool } = require('../config/db');
const crypto = require('crypto');

class CurrencyService {
  async getSettings() {
    try {
      const [rows] = await pool.query(
        `SELECT \`key\`, \`value\`, \`updated_at\` FROM system_settings 
         WHERE \`key\` IN ('global_default_currency', 'usd_exchange_rate', 'allow_buyer_currency_toggle')`
      );

      const map = {};
      let lastUpdated = new Date().toISOString();
      rows.forEach((r) => {
        map[r.key] = r.value;
        if (r.updated_at) lastUpdated = r.updated_at;
      });

      const defaultCurrency = (map['global_default_currency'] || 'INR').replace(/["']/g, '').trim().toUpperCase();
      const rawRate = (map['usd_exchange_rate'] || '85.0').replace(/["']/g, '').trim();
      const usdExchangeRate = Number(rawRate) || 85.0;
      const allowBuyerSwitch = map['allow_buyer_currency_toggle'] !== 'false' && map['allow_buyer_currency_toggle'] !== false;

      return {
        success: true,
        defaultCurrency: defaultCurrency === 'USD' ? 'USD' : 'INR',
        usdExchangeRate: usdExchangeRate > 0 ? usdExchangeRate : 85.0,
        allowBuyerSwitch,
        updatedAt: lastUpdated,
      };
    } catch (err) {
      console.error('[CurrencyService] getSettings error:', err);
      return {
        success: true,
        defaultCurrency: 'INR',
        usdExchangeRate: 85.0,
        allowBuyerSwitch: true,
        updatedAt: new Date().toISOString(),
      };
    }
  }

  async updateSettings({ defaultCurrency, usdExchangeRate, allowBuyerSwitch = true }) {
    const validCurr = (defaultCurrency || 'INR').toUpperCase() === 'USD' ? 'USD' : 'INR';
    const validRate = Number(usdExchangeRate) > 0 ? Number(usdExchangeRate) : 85.0;
    const validAllow = allowBuyerSwitch !== false;

    const upsertSetting = async (key, value, description) => {
      const [existing] = await pool.query('SELECT id FROM system_settings WHERE `key` = ?', [key]);
      if (existing.length > 0) {
        await pool.query(
          'UPDATE system_settings SET `value` = ?, `updated_at` = NOW() WHERE `key` = ?',
          [String(value), key]
        );
      } else {
        const id = crypto.randomUUID();
        await pool.query(
          'INSERT INTO system_settings (id, `key`, `value`, `description`, is_sensitive, created_at, updated_at) VALUES (?, ?, ?, ?, 0, NOW(), NOW())',
          [id, key, String(value), description]
        );
      }
    };

    await upsertSetting('global_default_currency', validCurr, 'Global default pricing currency for buyers');
    await upsertSetting('usd_exchange_rate', validRate.toFixed(2), 'USD to INR exchange rate for service pricing');
    await upsertSetting('allow_buyer_currency_toggle', String(validAllow), 'Whether buyers can toggle currency in app');

    return {
      success: true,
      defaultCurrency: validCurr,
      usdExchangeRate: validRate,
      allowBuyerSwitch: validAllow,
      updatedAt: new Date().toISOString(),
    };
  }
}

module.exports = new CurrencyService();
