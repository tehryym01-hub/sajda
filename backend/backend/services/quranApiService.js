const QURAN_API = 'https://api.quran.com/api/v4';

const PUBLIC_DOMAIN_TRANSLATORS = [
  'Sahih International',
  'Muhsin Khan',
  'Pickthall',
  'Yusuf Ali',
];

async function fetchWithTimeout(url, options = {}, timeout = 5000) {
  return Promise.race([
    fetch(url, options),
    new Promise((_, reject) => 
      setTimeout(() => reject(new Error('Request timeout')), timeout)
    )
  ]);
}

export async function fetchVersesBySurah(surahNumber) {
  try {
    const url = `${QURAN_API}/quran/surahs/${surahNumber}`;
    const res = await fetchWithTimeout(url, {
      headers: { 'Accept': 'application/json' }
    });
    if (!res.ok) return [];
    const data = await res.json();
    const surah = data?.surah;
    if (!surah) return [];
    
    return (surah.verses || []).map(v => {
      const translation = (v.translations || []).find(t => 
        PUBLIC_DOMAIN_TRANSLATORS.some(pd => 
          (t.translator_name || '').toLowerCase().includes(pd.toLowerCase())
        )
      );
      
      return {
        arabic: v.text_uthmani || '',
        english: translation?.text || '',
        urdu: '',
        reference: `Quran ${v.verse_key}`,
        source: 'quran.com',
      };
    });
  } catch {
    return [];
  }
}
