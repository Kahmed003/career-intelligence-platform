export function MatchScore({score}:{score?:number|null}){
 const value=score==null?null:Math.round(Number(score));
 return <div className="match-score"><strong>{value==null?"—":value}</strong><span>match</span></div>;
}
