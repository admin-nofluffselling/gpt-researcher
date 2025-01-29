import ReactGA from 'react-ga4';

interface ResearchData {
  query: string;
  report_type: string;
  report_source: string;
}

export const useAnalytics = () => {
  const trackResearchQuery = (data: ResearchData) => {
    ReactGA.event({
      category: 'Research',
      action: 'Submit Query',
      label: data.query,
      // Custom dimensions should be passed in the event parameters
      value: 1,
      nonInteraction: false,
      transport: 'beacon',
      // Pass custom data as a stringified object in the event label
      customLabel: JSON.stringify({
        query: data.query,
        report_type: data.report_type,
        report_source: data.report_source
      })
    });
  };

  return {
    trackResearchQuery
  };
};

export default useAnalytics;